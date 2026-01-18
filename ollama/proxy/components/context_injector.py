"""Context injector for Atlas proxy.

Automatically excavates relationships in stored data by identifying files/memories
that relate to the conversation topic through keyword-weighted scoring.

Workflow:
1. Extract and count keywords from conversation (e.g., red:68, flag:150)
2. Build tag index mapping tag:keyword -> files
3. Score files by: (num_matched_keywords * 10) + sum_of_keyword_counts
4. Inject files hierarchically (highest score first) until context limit reached

This automatically surfaces files that match multiple conversation keywords or
high-weighted keywords, discovering relationships without manual organization.
"""

import logging
import os
import re
import time
from collections import Counter
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)


class ContextInjector:
    """Keyword-weighted context injector for automatic relationship discovery.
    
    Uses keyword mention counts to weight importance and surface relevant files
    hierarchically. Files matching multiple keywords or high-weighted keywords
    are automatically prioritized.
    """

    def __init__(self, files_dir: str, max_context_size: int = 2000, cache_ttl: int = 60, 
                 max_context_tokens: int = 32768, dynamic_context: bool = True):
        """Initialize ContextInjector instance.
        
        Args:
            files_dir: Base directory path where files are stored.
            max_context_size: Maximum context size in characters (default: 2000).
                            **RECOMMENDED: 10000-20000** for practical RAG use.
                            Current default (2000) is too small for referencing full files.
                            Ignored if dynamic_context=True.
            cache_ttl: Cache time-to-live in seconds (default: 60).
            max_context_tokens: Total context window size in tokens (default: 32768 from Modelfile).
            dynamic_context: If True, calculate max_context_size dynamically based on available space.
        """
        self.files_dir = Path(files_dir).resolve()
        self.max_context_size = max_context_size
        self.cache_ttl = cache_ttl
        self.max_context_tokens = max_context_tokens
        self.dynamic_context = dynamic_context
        
        # Cache for file context
        self._cached_context: Optional[Dict[str, Any]] = None
        self._cache_timestamp: float = 0
        
        # Cache for tag index (maps tag -> list of file paths)
        self._tag_index: Optional[Dict[str, List[str]]] = None
        self._tag_index_timestamp: float = 0
        
        # Ensure files directory exists
        try:
            self.files_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            logger.error(f"Error creating files directory {self.files_dir}: {e}")

    def extract_keywords(self, messages: List[Dict[str, Any]]) -> Dict[str, int]:
        """Extract keywords from conversation messages and count mentions.
        
        Preserves case to distinguish concepts (e.g., "RED" movie vs "red" color).
        Tag matching is case-insensitive, but original case is preserved for disambiguation.
        
        Pure script-based processing - no agent/LLM required. Uses regex, counting, and
        stop word filtering to extract meaningful keywords.
        
        Args:
            messages: List of message dicts with "role" and "content" keys.
            
        Returns:
            Dictionary mapping keywords (preserving case) to mention counts 
            (e.g., {"RED": 5, "red": 10, "Monica": 3, "task": 5, "AI": 10}).
        """
        keyword_counts = Counter()
        
        # Common stop words to ignore (lowercase for comparison)
        stop_words = {
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
            "of", "with", "by", "from", "as", "is", "are", "was", "were", "be",
            "been", "being", "have", "has", "had", "do", "does", "did", "will",
            "would", "could", "should", "may", "might", "must", "can", "this",
            "that", "these", "those", "i", "you", "he", "she", "it", "we", "they",
            "what", "which", "who", "when", "where", "why", "how", "all", "each",
            "every", "some", "any", "no", "not", "if", "then", "else", "about",
            "into", "through", "during", "before", "after", "above", "below",
            "up", "down", "out", "off", "over", "under", "again", "further",
            "then", "once", "here", "there", "when", "where", "why", "how",
            "all", "both", "each", "few", "more", "most", "other", "some", "such",
            "no", "nor", "only", "own", "same", "so", "than", "too", "very",
            "can", "will", "just", "don", "should", "now"
        }
        
        for msg in messages:
            content = msg.get("content", "")
            if not content or not isinstance(content, str):
                continue
            
            # Extract words preserving case (alphanumeric sequences)
            # This captures "RED", "Red", "red", "AI", "ai", etc. as separate keywords
            words = re.findall(r'\b[a-zA-Z]+\b', content)
            
            # Count words that meet criteria
            # Only filter out single-letter words (to preserve acronyms like AI, API, etc.)
            for word in words:
                if len(word) > 1 and word.lower() not in stop_words:
                    keyword_counts[word] += 1  # Preserve original case
        
        return dict(keyword_counts)
    
    def _build_tag_index(self, force_refresh: bool = False) -> Dict[str, List[str]]:
        """Build index of files by tags (tag:keyword patterns).
        
        Scans all files for tag:keyword patterns and builds an index.
        
        Args:
            force_refresh: If True, rebuild index even if cached.
            
        Returns:
            Dictionary mapping tags to lists of file paths.
        """
        # Check cache
        current_time = time.time()
        if not force_refresh and self._tag_index is not None:
            if current_time - self._tag_index_timestamp < self.cache_ttl:
                logger.debug("Returning cached tag index")
                return self._tag_index
        
        tag_index: Dict[str, List[str]] = {}
        
        if not self.files_dir.exists():
            logger.debug(f"Files directory does not exist: {self.files_dir}")
            return tag_index
        
        try:
            # Scan all files for tag:keyword patterns
            tag_pattern = re.compile(r'tag:(\w+)', re.IGNORECASE)
            
            for file_path in self.files_dir.rglob('*'):
                if file_path.is_file() and file_path.suffix in ['.txt', '.md']:
                    try:
                        # Read file content
                        content = file_path.read_text(encoding='utf-8', errors='ignore')
                        
                        # Find all tag:keyword patterns
                        tags = tag_pattern.findall(content)
                        
                        # Add file to index for each tag found
                        rel_path = str(file_path.relative_to(self.files_dir))
                        for tag in tags:
                            tag_lower = tag.lower()
                            if tag_lower not in tag_index:
                                tag_index[tag_lower] = []
                            if rel_path not in tag_index[tag_lower]:
                                tag_index[tag_lower].append(rel_path)
                    except (OSError, ValueError, UnicodeDecodeError) as e:
                        logger.debug(f"Error reading file {file_path}: {e}")
                        continue
            
            # Update cache
            self._tag_index = tag_index
            self._tag_index_timestamp = current_time
            logger.debug(f"Built tag index with {len(tag_index)} tags")
            
        except Exception as e:
            logger.error(f"Error building tag index: {e}")
        
        return tag_index
    
    def _count_keywords_in_file(self, file_path: Path, keywords: List[str]) -> Dict[str, int]:
        """Count how many times each keyword appears in a file (case-insensitive matching).
        
        Matches case-insensitively but returns counts keyed by original keyword case.
        This allows "RED" and "red" to be tracked separately in conversation, but
        both match the same occurrences in files.
        
        Args:
            file_path: Path to the file to scan.
            keywords: List of keywords to count (preserving original case from conversation).
            
        Returns:
            Dictionary mapping keyword (original case) to count in file.
        """
        keyword_counts = {}
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            content_lower = content.lower()
            
            for keyword in keywords:
                keyword_lower = keyword.lower()
                # Count word boundaries (whole words only, case-insensitive)
                pattern = r'\b' + re.escape(keyword_lower) + r'\b'
                count = len(re.findall(pattern, content_lower))
                if count > 0:
                    keyword_counts[keyword] = count  # Key by original case
        except (OSError, ValueError, UnicodeDecodeError) as e:
            logger.debug(f"Error counting keywords in {file_path}: {e}")
        
        return keyword_counts
    
    def _get_relevant_files(self, keywords: Dict[str, int]) -> List[Dict[str, Any]]:
        """Get list of relevant files with scoring and ranking based on keyword mentions and tags.
        
        Scores files with multi-keyword matching as PRIMARY factor, file frequency as bonus:
        - PRIMARY: Multi-keyword matching - files matching more keywords rank much higher
        - BONUS: File keyword frequency - conversation_count * file_count adds to score
        - Formula: score = (number_of_matched_keywords * 10000) + sum(conversation_count * file_count)
        
        This ensures files matching multiple conversation keywords rank highest, with file frequency
        as a tiebreaker. Example: File matching 3 keywords always beats file matching 1 keyword,
        regardless of frequency counts.
        
        Args:
            keywords: Dictionary mapping keywords to mention counts (e.g., {"red": 68, "flag": 150}).
            
        Returns:
            List of file info dicts sorted by relevance score (highest first), each containing:
            - path: File path
            - score: Relevance score
            - matched_keywords: List of (keyword, conv_count, file_count) tuples
            - num_matches: Number of matched keywords
        """
        tag_index = self._build_tag_index()
        
        # Build file -> matched keywords mapping
        file_matches: Dict[str, List[tuple]] = {}  # path -> [(keyword, conv_count), ...]
        
        # Find all files that match any keyword (case-insensitive tag matching)
        # Tags are case-insensitive, but we preserve original keyword case
        for keyword, conv_count in keywords.items():
            keyword_lower = keyword.lower()
            if keyword_lower in tag_index:
                for file_path in tag_index[keyword_lower]:
                    if file_path not in file_matches:
                        file_matches[file_path] = []
                    file_matches[file_path].append((keyword, conv_count))  # Preserve original case
        
        if not file_matches:
            logger.debug("No files match any keywords")
            return []
        
        # Score and rank files
        scored_files = []
        for file_path_str, matched_keywords in file_matches.items():
            file_path = self.files_dir / file_path_str
            
            # Count how many times each matched keyword appears in the file
            matched_keyword_names = [kw for kw, _ in matched_keywords]
            file_keyword_counts = self._count_keywords_in_file(file_path, matched_keyword_names)
            
            # Calculate weighted score: multi-keyword matching is PRIMARY, frequency is BONUS
            weighted_products = []
            matched_with_counts = []
            
            for keyword, conv_count in matched_keywords:
                file_count = file_keyword_counts.get(keyword.lower(), 0)
                if file_count > 0:  # Only include if keyword actually appears in file
                    product = conv_count * file_count
                    weighted_products.append(product)
                    matched_with_counts.append((keyword, conv_count, file_count))
            
            if not weighted_products:
                continue  # Skip files where keywords don't actually appear
            
            num_matches = len(matched_with_counts)
            weighted_sum = sum(weighted_products)
            # PRIMARY: Multi-keyword matching (10000x multiplier)
            # BONUS: File keyword frequency (additive)
            score = (num_matches * 10000) + weighted_sum
            
            scored_files.append({
                "path": file_path_str,
                "score": score,
                "matched_keywords": matched_with_counts,  # (keyword, conv_count, file_count)
                "num_matches": num_matches,
                "weighted_sum": weighted_sum
            })
        
        # Sort by score (highest first), then by number of matches, then by weighted sum
        scored_files.sort(key=lambda x: (x["score"], x["num_matches"], x["weighted_sum"]), reverse=True)
        
        logger.debug(f"Scored {len(scored_files)} files. Top 3 scores: {[f['score'] for f in scored_files[:3]]}")
        return scored_files
    
    def load_file_context(self, messages: Optional[List[Dict[str, Any]]] = None, force_refresh: bool = False) -> Dict[str, Any]:
        """Load file context based on keyword mentions in conversation.
        
        Only loads and returns context for files that match keywords via tags.
        If no keywords match, returns empty context (no file listings injected).
        
        Args:
            messages: List of conversation messages to extract keywords from.
            force_refresh: If True, bypass cache and reload context.
        
        Returns:
            Dictionary with "relevant_files" (list of file paths with content) and "keywords" keys.
        """
        context = {
            "relevant_files": [],
            "keywords": {}
        }
        
        # If no messages provided, return empty context (no injection)
        if not messages:
            logger.debug("No messages provided, returning empty context")
            return context
        
        # Extract keywords from conversation
        keywords = self.extract_keywords(messages)
        context["keywords"] = keywords
        
        if not keywords:
            logger.debug("No keywords extracted from conversation")
            return context
        
        # Get relevant files with scoring and ranking
        scored_files = self._get_relevant_files(keywords)
        
        if not scored_files:
            logger.debug("No files match keywords, returning empty context")
            return context
        
        # Load content of relevant files (already sorted by score, highest first)
        try:
            for file_info in scored_files:
                rel_path = file_info["path"]
                file_path = self.files_dir / rel_path
                if file_path.exists() and file_path.is_file():
                    try:
                        content = file_path.read_text(encoding='utf-8', errors='ignore')
                        stat = file_path.stat()
                        context["relevant_files"].append({
                            "path": rel_path,
                            "content": content,
                            "size": stat.st_size,
                            "modified": stat.st_mtime,
                            "score": file_info["score"],
                            "matched_keywords": file_info["matched_keywords"],
                            "num_matches": file_info["num_matches"]
                        })
                    except (OSError, ValueError, UnicodeDecodeError) as e:
                        logger.debug(f"Error reading file {file_path}: {e}")
                        continue
        except Exception as e:
            logger.error(f"Error loading relevant files: {e}")
        
        top_keywords = sorted(keywords.items(), key=lambda x: x[1], reverse=True)[:5]
        logger.info(f"Loaded {len(context['relevant_files'])} relevant files. Top keywords: {dict(top_keywords)}")
        return context

    def _build_directory_structure(self, root_dir: Path, prefix: str = "", is_last: bool = True) -> List[str]:
        """Build directory structure in tree format.
        
        Args:
            root_dir: Root directory to traverse.
            prefix: Prefix for tree visualization.
            is_last: Whether this is the last item at this level.
            
        Returns:
            List of directory structure lines.
        """
        lines = []
        
        try:
            # Get directories only
            dirs = sorted([d for d in root_dir.iterdir() if d.is_dir()], key=lambda x: x.name)
            
            for i, dir_path in enumerate(dirs):
                is_last_dir = (i == len(dirs) - 1)
                connector = "└── " if is_last_dir else "├── "
                lines.append(f"{prefix}{connector}{dir_path.name}/")
                
                # Recursively build subdirectories
                extension = "    " if is_last_dir else "│   "
                sub_lines = self._build_directory_structure(
                    dir_path,
                    prefix + extension,
                    is_last_dir
                )
                lines.extend(sub_lines)
        
        except PermissionError:
            logger.debug(f"Permission denied accessing {root_dir}")
        except Exception as e:
            logger.debug(f"Error building directory structure for {root_dir}: {e}")
        
        return lines

    def _build_file_listings(self, root_dir: Path) -> Dict[str, List[Dict[str, Any]]]:
        """Build file listings organized by directory.
        
        Args:
            root_dir: Root directory to traverse.
            
        Returns:
            Dictionary mapping directory paths to lists of file info dicts.
        """
        listings = {}
        
        try:
            # Walk through all directories
            for dir_path in root_dir.rglob('*'):
                if dir_path.is_dir():
                    files = []
                    for file_path in sorted(dir_path.iterdir()):
                        if file_path.is_file():
                            try:
                                stat = file_path.stat()
                                rel_path = file_path.relative_to(self.files_dir)
                                files.append({
                                    "name": file_path.name,
                                    "path": str(rel_path),
                                    "size": stat.st_size,
                                    "modified": stat.st_mtime
                                })
                            except (OSError, ValueError) as e:
                                logger.debug(f"Error getting file info for {file_path}: {e}")
                    
                    if files:
                        rel_dir = dir_path.relative_to(self.files_dir)
                        listings[str(rel_dir)] = files
        
        except Exception as e:
            logger.error(f"Error building file listings: {e}")
        
        return listings

    def _get_recent_files(self, root_dir: Path, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent files sorted by modification time.
        
        Args:
            root_dir: Root directory to search.
            limit: Maximum number of recent files to return.
            
        Returns:
            List of file info dicts sorted by modification time (most recent first).
        """
        recent_files = []
        current_time = time.time()
        
        try:
            for file_path in root_dir.rglob('*'):
                if file_path.is_file():
                    try:
                        stat = file_path.stat()
                        rel_path = file_path.relative_to(self.files_dir)
                        mtime = stat.st_mtime
                        recent_files.append({
                            "name": file_path.name,
                            "path": str(rel_path),
                            "size": stat.st_size,
                            "modified": mtime,
                            "relative_time": self._format_relative_time(current_time - mtime)
                        })
                    except (OSError, ValueError):
                        continue
            
            # Sort by modification time (most recent first)
            recent_files.sort(key=lambda x: x["modified"], reverse=True)
            recent_files = recent_files[:limit]
            
        except Exception as e:
            logger.error(f"Error getting recent files: {e}")
        
        return recent_files

    def _format_relative_time(self, seconds: float) -> str:
        """Format time difference as relative time string.
        
        Args:
            seconds: Time difference in seconds.
            
        Returns:
            Relative time string like "2 hours ago", "5 minutes ago", etc.
        """
        if seconds < 60:
            return "just now"
        elif seconds < 3600:
            minutes = int(seconds / 60)
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif seconds < 86400:
            hours = int(seconds / 3600)
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif seconds < 604800:
            days = int(seconds / 86400)
            return f"{days} day{'s' if days != 1 else ''} ago"
        elif seconds < 2592000:
            weeks = int(seconds / 604800)
            return f"{weeks} week{'s' if weeks != 1 else ''} ago"
        elif seconds < 31536000:
            months = int(seconds / 2592000)
            return f"{months} month{'s' if months != 1 else ''} ago"
        else:
            years = int(seconds / 31536000)
            return f"{years} year{'s' if years != 1 else ''} ago"

    def _estimate_tokens(self, text: str) -> int:
        """Estimate token count from character count.
        
        Rough approximation: ~4 characters per token for English text.
        This is conservative - actual tokenization varies.
        
        Args:
            text: Text to estimate tokens for.
            
        Returns:
            Estimated token count.
        """
        return len(text) // 4
    
    def _calculate_dynamic_context_size(self, messages: List[Dict[str, Any]], 
                                       system_prompt_tokens: int = 1000,
                                       response_reserve_tokens: int = 2000) -> int:
        """Calculate dynamic context size based on available space.
        
        Args:
            messages: List of conversation messages to estimate size for.
            system_prompt_tokens: Estimated system prompt size (default: 1000).
            response_reserve_tokens: Tokens to reserve for model response (default: 2000).
            
        Returns:
            Maximum context size in characters.
        """
        # Estimate conversation history size
        conversation_text = ""
        for msg in messages:
            content = msg.get("content", "")
            if isinstance(content, str):
                conversation_text += content + "\n"
        
        conversation_tokens = self._estimate_tokens(conversation_text)
        
        # Calculate available space
        # Total: max_context_tokens
        # Used: system_prompt + conversation_history + response_reserve
        # Available: total - used
        used_tokens = system_prompt_tokens + conversation_tokens + response_reserve_tokens
        available_tokens = max(0, self.max_context_tokens - used_tokens)
        
        # Convert to characters (4 chars per token, use 90% to be safe)
        available_chars = int((available_tokens * 4) * 0.9)
        
        # Set reasonable bounds
        min_context = 5000  # Minimum 5k chars for practical use
        max_context = 50000  # Maximum 50k chars (safety limit)
        
        dynamic_size = max(min_context, min(available_chars, max_context))
        
        logger.debug(f"Dynamic context: {conversation_tokens} conv tokens, "
                    f"{available_tokens} available tokens, "
                    f"{dynamic_size} chars available for injection")
        
        return dynamic_size
    
    def format_context(self, file_context: Dict[str, Any], variables: Dict[str, Any], 
                      messages: Optional[List[Dict[str, Any]]] = None) -> str:
        """Format context for prompt inclusion with hierarchical ranking.
        
        Only includes relevant files that matched keywords via tags, in order of relevance score.
        Respects max_context_size limit (dynamic or fixed), injecting highest-scored files first.
        
        Args:
            file_context: Dictionary from load_file_context().
            variables: Dictionary of variables to include.
            messages: Optional list of messages for dynamic context size calculation.
            
        Returns:
            Formatted context string for prompt inclusion, or empty string if no relevant context.
        """
        # Calculate dynamic context size if enabled
        if self.dynamic_context and messages:
            effective_max_size = self._calculate_dynamic_context_size(messages)
        else:
            effective_max_size = self.max_context_size
        
        parts = []
        current_size = 0
        
        # Only format if we have relevant files (keyword-based matching worked)
        relevant_files = file_context.get("relevant_files", [])
        keywords = file_context.get("keywords", {})
        
        if not relevant_files:
            logger.debug("No relevant files to format, returning empty context")
            return ""
        
        # Show top keywords that triggered the context
        top_keywords = sorted(keywords.items(), key=lambda x: x[1], reverse=True)[:5]
        if top_keywords:
            kw_list = ", ".join([f"{kw}:{count}" for kw, count in top_keywords])
            header = f"**Relevant Context** (triggered by: {kw_list}):"
            parts.append(header)
            current_size += len(header)
        
        # Format relevant files with their content (already sorted by score, highest first)
        for file_info in relevant_files:
            rel_path = file_info["path"]
            content = file_info.get("content", "")
            score = file_info.get("score", 0)
            matched_keywords = file_info.get("matched_keywords", [])
            num_matches = file_info.get("num_matches", 0)
            
            # Format matched keywords for display (shows conv_count and file_count)
            # matched_keywords is list of (keyword, conv_count, file_count) tuples
            matched_str = ", ".join([
                f"{kw}(conv:{conv}, file:{file})" 
                for kw, conv, file in matched_keywords
            ])
            
            # Build file header with score and matched keywords
            file_header = f"\n**File: {rel_path}** (score: {score}, matches: {num_matches} keywords - {matched_str})"
            
            # Estimate size needed for this file
            # Truncate very long files to fit in context
            max_file_size = min(2000, effective_max_size - current_size - len(file_header) - 100)
            if len(content) > max_file_size:
                content = content[:max_file_size] + "\n[... truncated ...]"
            
            file_content = f"```\n{content}\n```"
            file_total_size = len(file_header) + len(file_content)
            
            # Check if adding this file would exceed limit
            if current_size + file_total_size > effective_max_size:
                # Try to fit a truncated version
                remaining_space = effective_max_size - current_size - len(file_header) - 50
                if remaining_space > 100:  # Only add if we have meaningful space
                    truncated_content = content[:remaining_space] + "\n[... truncated due to context limit ...]"
                    parts.append(file_header)
                    parts.append("```")
                    parts.append(truncated_content)
                    parts.append("```")
                break  # Stop adding files
            
            # Add file
            parts.append(file_header)
            parts.append("```")
            parts.append(content)
            parts.append("```")
            current_size += file_total_size
        
        # Format variables (if space allows)
        if variables:
            filtered = {k: v for k, v in variables.items() if k != "_metadata"}
            if filtered:
                vars_str = "\n**Variables:** " + ", ".join([f"{k}={v}" for k, v in sorted(filtered.items())])
                if current_size + len(vars_str) <= effective_max_size:
                    parts.append(vars_str)
                    current_size += len(vars_str)
        
        context_str = "\n".join(parts)
        
        # Final truncation if needed (shouldn't happen, but safety check)
        if len(context_str) > effective_max_size:
            context_str = context_str[:effective_max_size]
            last_newline = context_str.rfind('\n')
            if last_newline > effective_max_size * 0.8:
                context_str = context_str[:last_newline]
            context_str += "\n\n[... context truncated ...]"
        
        return context_str

    def inject_into_messages(self, messages: List[Dict[str, Any]], context: str) -> List[Dict[str, Any]]:
        """Inject context into message list.
        
        Injects context into the first user message, or creates a system message
        if no user message exists. If a system message already exists, prepends
        context to it.
        
        Args:
            messages: List of message dicts with "role" and "content" keys.
            context: Formatted context string to inject.
            
        Returns:
            New list of messages with context injected.
        """
        if not context or not context.strip():
            return messages.copy()
        
        # Create new messages list
        new_messages = []
        context_injected = False
        
        # Find first user message
        for i, msg in enumerate(messages):
            if msg.get("role") == "user" and not context_injected:
                # Inject context into first user message
                existing_content = msg.get("content", "")
                new_content = f"{context}\n\n{existing_content}".strip()
                new_messages.append({
                    "role": "user",
                    "content": new_content
                })
                context_injected = True
            else:
                # Check if this is a system message and we haven't injected yet
                if msg.get("role") == "system" and not context_injected:
                    # Prepend context to existing system message
                    existing_content = msg.get("content", "")
                    new_content = f"{context}\n\n{existing_content}".strip()
                    new_messages.append({
                        "role": "system",
                        "content": new_content
                    })
                    context_injected = True
                else:
                    # Add message as-is
                    new_messages.append(msg)
        
        # If no user or system message found, create system message at start
        if not context_injected:
            new_messages.insert(0, {
                "role": "system",
                "content": context
            })
        
        return new_messages

