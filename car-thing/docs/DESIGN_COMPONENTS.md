# Design Components Reference

Pre-built components from `src/design/components/`. Import from `@/design/components` or relative path.

---

## Button

```tsx
import { Button } from '@/design/components'

<Button variant="primary" onClick={...}>Save</Button>
<Button variant="secondary" icon={<Icon />}>Cancel</Button>
<Button variant="ghost" size="lg">More</Button>
<Button variant="danger">Delete</Button>
```

**Props:** `variant` (primary|secondary|ghost|danger), `size` (md|lg), `icon`, `disabled`, standard button attrs.

---

## Card

```tsx
<Card>Content</Card>
<Card placeholder>Coming soon</Card>
```

**Props:** `placeholder` — dashed border for placeholders.

---

## ControlRow

Label left, control right. Min 44px height.

```tsx
<ControlRow label="Mic mute">
  <Switch checked={muted} onCheckedChange={setMuted} variant="danger" />
</ControlRow>
```

---

## Switch

Styled Radix switch. Use `variant="danger"` for mute/stop.

```tsx
<Switch checked={muted} onCheckedChange={setMuted} variant="danger" />
```

---

## SectionHeader

```tsx
<SectionHeader title="Audio" hint="Control output and input" />
```

---

## EmptyState

```tsx
<EmptyState
  icon="📭"
  message="No notifications configured yet."
  hint="Add a fetcher service to enable."
/>
```

---

## MacroButton

Grid-friendly macro launcher.

```tsx
<MacroButton id="mute" label="Mute Teams" icon="🎤" onClick={() => run('mute')} />
```

---

## TabBar + TabContent

```tsx
<TabBar tabs={[{ value: 'control', label: 'Control' }, ...]} defaultValue="control">
  <TabContent value="control" className="mt-3 flex-1"><ControlTab /></TabContent>
  <TabContent value="macros" className="mt-3 flex-1"><MacrosTab /></TabContent>
</TabBar>
```

---

## Spinner

```tsx
<Spinner size="sm" />
```
