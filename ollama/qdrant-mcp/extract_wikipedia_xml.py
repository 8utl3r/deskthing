#!/usr/bin/env python3
"""Extract text from Wikipedia XML dump."""

import bz2
import xml.etree.ElementTree as ET
import sys
from pathlib import Path

def extract_articles(xml_file, output_dir):
    """Extract articles from Wikipedia XML dump."""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    article_count = 0
    
    print(f"Extracting from {xml_file}...")
    
    # Use iterparse for memory efficiency
    context = ET.iterparse(bz2.open(xml_file, 'rb'), events=('start', 'end'))
    
    current_title = None
    current_text = None
    in_text = False
    
    for event, elem in context:
        if event == 'start':
            if elem.tag.endswith('title'):
                current_title = None
            elif elem.tag.endswith('text'):
                in_text = True
                current_text = None
        elif event == 'end':
            if elem.tag.endswith('title') and elem.text:
                current_title = elem.text.strip()
            elif elem.tag.endswith('text') and elem.text:
                current_text = elem.text.strip()
            elif elem.tag.endswith('page'):
                # End of page, save if we have title and text
                if current_title and current_text and len(current_text) > 100:
                    # Clean title for filename
                    safe_title = current_title.replace('/', '_').replace('\\', '_').replace(':', '_')
                    safe_title = ''.join(c for c in safe_title if c.isalnum() or c in (' ', '_', '-'))[:100]
                    
                    output_file = output_path / f"{safe_title}.txt"
                    try:
                        output_file.write_text(current_text, encoding='utf-8')
                        article_count += 1
                        if article_count % 100 == 0:
                            print(f"Extracted {article_count} articles...")
                    except Exception as e:
                        print(f"Error writing {safe_title}: {e}")
                
                # Clear element to free memory
                elem.clear()
                current_title = None
                current_text = None
                in_text = False
    
    print(f"✅ Extracted {article_count} articles to {output_dir}")
    return article_count

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: extract_wikipedia_xml.py <input.xml.bz2> <output_dir>")
        sys.exit(1)
    
    xml_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    extract_articles(xml_file, output_dir)
