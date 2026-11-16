import { useState, type ReactNode } from "react";
import {
  Accordion,
  Badge,
  Button,
  Display,
  Eyebrow,
  FeatureGrid,
  Field,
  Frame,
  Kbd,
  SectionHeader,
  SpecList,
  StatGrid,
  Switch,
  TextLink,
  TopBar,
} from "../../ui/index.js";

const palette = [
  "bg-deep",
  "bg-dark",
  "bg",
  "bg-storm",
  "bg-highlight",
  "gutter",
  "terminal-black",
  "comment",
  "dark5",
  "fg-dark",
  "fg",
  "fg-bright",
  "blue",
  "cyan",
  "teal",
  "green",
  "yellow",
  "orange",
  "red",
  "magenta",
];

const semantic: Record<string, string[]> = {
  Surface: [
    "canvas",
    "surface",
    "surface-raised",
    "surface-hover",
    "surface-sunken",
  ],
  Line: ["border-subtle", "border", "border-strong"],
  Text: ["text-strong", "text", "text-secondary", "text-muted", "text-faint"],
  Intent: [
    "primary",
    "accent",
    "info",
    "success",
    "warning",
    "danger",
    "highlight",
    "link",
  ],
};

const typeScale = [
  { token: "display-xl", family: "display", sample: "Unshell" },
  { token: "display-lg", family: "display", sample: "A place to work." },
  {
    token: "display-md",
    family: "display",
    sample: "Workspaces, agents, automation.",
  },
  {
    token: "title",
    family: "sans",
    sample: "Change anything. Reinstall nothing.",
  },
  {
    token: "body-lg",
    family: "sans",
    sample: "Every workspace keeps its repos, trees and knowledge together.",
  },
  {
    token: "body",
    family: "sans",
    sample:
      "Agents run inside the same environment you do, with the same tools.",
  },
  { token: "small", family: "sans", sample: "Last synced 2 minutes ago" },
  { token: "label", family: "mono", sample: "WORKSPACE · MAIN · CLEAN" },
];

const spaces = ["1", "2", "3", "4", "5", "6", "8", "10", "12", "16"];
const radii = ["none", "xs", "sm", "full"];
const shadows = ["1", "2", "3", "glow"];
const easings = ["standard", "emphasized", "exit"];
const durations = ["instant", "fast", "base", "slow"];

function Block({
  index,
  title,
  glyph,
  children,
}: {
  index: string;
  title: string;
  glyph: string;
  children: ReactNode;
}) {
  return (
    <section className="ds-block">
      <SectionHeader index={index} title={title} glyph={glyph} />
      {children}
    </section>
  );
}

function Specimen({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="ds-specimen">
      <Eyebrow>{label}</Eyebrow>
      <div className="ds-specimen-body">{children}</div>
    </div>
  );
}

export function DesignSystemView() {
  const [enabled, setEnabled] = useState(true);
  const [nav, setNav] = useState("workspaces");
  const [moved, setMoved] = useState(false);

  return (
    <div className="ds">
      <header className="ds-hero">
        <Eyebrow>Unshell · Design system · Tokyo Night</Eyebrow>
        <Display size="xl">Unshell</Display>
        <p className="ds-lede">
          Editorial type, hairline rules and square controls on the Tokyo Night
          palette. Everything here reads from <code>tokens.css</code> and{" "}
          <code>ui/</code>.
        </p>
      </header>

      <Block index="01" title="Colour" glyph="色">
        <Specimen label="Tokyo Night palette">
          <div className="ds-swatches">
            {palette.map((name) => (
              <figure key={name} className="ds-swatch">
                <div style={{ background: `var(--tn-${name})` }} />
                <figcaption>--tn-{name}</figcaption>
              </figure>
            ))}
          </div>
        </Specimen>
        {Object.entries(semantic).map(([group, names]) => (
          <Specimen key={group} label={`Semantic · ${group}`}>
            <div className="ds-swatches">
              {names.map((name) => (
                <figure key={name} className="ds-swatch">
                  <div style={{ background: `var(--color-${name})` }} />
                  <figcaption>--color-{name}</figcaption>
                </figure>
              ))}
            </div>
          </Specimen>
        ))}
      </Block>

      <Block index="02" title="Typography" glyph="字">
        <div className="ds-type">
          {typeScale.map((row) => (
            <div key={row.token} className="ds-type-row">
              <code>--text-{row.token}</code>
              <span
                style={{
                  fontFamily: `var(--font-${row.family})`,
                  fontSize: `var(--text-${row.token})`,
                  lineHeight:
                    row.family === "display"
                      ? "var(--leading-tight)"
                      : undefined,
                  letterSpacing:
                    row.family === "display"
                      ? "var(--tracking-display)"
                      : row.family === "mono"
                        ? "var(--tracking-label)"
                        : undefined,
                }}
              >
                {row.sample}
              </span>
            </div>
          ))}
        </div>
      </Block>

      <Block index="03" title="Spacing" glyph="間">
        {spaces.map((step) => (
          <div key={step} className="ds-space">
            <code>--space-{step}</code>
            <span style={{ width: `var(--space-${step})` }} />
          </div>
        ))}
      </Block>

      <Block index="04" title="Radius and elevation" glyph="形">
        <Specimen label="Radius">
          <div className="ds-row">
            {radii.map((name) => (
              <figure key={name} className="ds-tile-wrap">
                <div
                  className="ds-tile"
                  style={{ borderRadius: `var(--radius-${name})` }}
                />
                <figcaption>--radius-{name}</figcaption>
              </figure>
            ))}
          </div>
        </Specimen>
        <Specimen label="Shadow (floating layers only)">
          <div className="ds-row">
            {shadows.map((name) => (
              <figure key={name} className="ds-tile-wrap">
                <div
                  className="ds-tile ds-tile--raised"
                  style={{ boxShadow: `var(--shadow-${name})` }}
                />
                <figcaption>--shadow-{name}</figcaption>
              </figure>
            ))}
          </div>
        </Specimen>
      </Block>

      <Block index="05" title="Motion" glyph="動">
        <div className="ds-row">
          <Button size="sm" onClick={() => setMoved((value) => !value)}>
            Play
          </Button>
          <span className="ds-muted">Respects reduced motion.</span>
        </div>
        {easings.map((easing) => (
          <div key={easing} className="ds-motion">
            <code>--ease-{easing}</code>
            <div className="ds-motion-track">
              <span
                style={{
                  transform: moved ? "translateX(280px)" : "none",
                  transition: `transform var(--duration-slow) var(--ease-${easing})`,
                }}
              />
            </div>
          </div>
        ))}
        <p className="ds-muted">
          Durations: {durations.map((name) => `--duration-${name}`).join(" · ")}
        </p>
      </Block>

      <Block index="06" title="Components" glyph="部">
        <Specimen label="Top bar">
          <div className="ds-bleed">
            <TopBar
              brand={
                <>
                  <span className="ds-mark">殻</span> Unshell
                </>
              }
              nav={[
                { id: "workspaces", label: "Workspaces" },
                { id: "agents", label: "Agents" },
                { id: "automation", label: "Automation" },
              ]}
              active={nav}
              onNavigate={setNav}
              actions={
                <>
                  <Badge dot tone="success">
                    v0.1.0
                  </Badge>
                  <Button size="sm">Docs</Button>
                  <Button size="sm" variant="primary">
                    New
                  </Button>
                </>
              }
            />
          </div>
        </Specimen>

        <Specimen label="Button">
          <div className="ds-row">
            <Button variant="primary">Install</Button>
            <Button>Source</Button>
            <Button variant="ghost">Cancel</Button>
            <Button variant="danger">Delete</Button>
            <Button disabled>Disabled</Button>
          </div>
          <div className="ds-row">
            <Button size="sm" variant="primary">
              Small
            </Button>
            <Button size="md" variant="primary">
              Medium
            </Button>
            <Button size="lg" variant="primary">
              Large
            </Button>
          </div>
        </Specimen>

        <Specimen label="Badge">
          <div className="ds-row">
            <Badge>neutral</Badge>
            <Badge dot tone="accent">
              1977
            </Badge>
            <Badge dot tone="info">
              syncing
            </Badge>
            <Badge dot tone="success">
              clean
            </Badge>
            <Badge dot tone="warning">
              2 changes
            </Badge>
            <Badge dot tone="danger">
              failed
            </Badge>
          </div>
        </Specimen>

        <Specimen label="Field and switch">
          <div className="ds-grid-2">
            <Field
              label="Workspace name"
              placeholder="unshell"
              hint="Lowercase, no spaces."
            />
            <Field
              label="Repository"
              defaultValue="git@gitlab.com:me/repo"
              error="Repository not reachable."
            />
          </div>
          <div className="ds-row">
            <Switch
              checked={enabled}
              onChange={setEnabled}
              label="Run agents on save"
            />
            <Switch
              checked={false}
              onChange={() => {}}
              label="Disabled"
              disabled
            />
          </div>
        </Specimen>

        <Specimen label="Inline">
          <p>
            Read the <TextLink href="#">workspace manual</TextLink>, or press{" "}
            <Kbd>⌘</Kbd> <Kbd>K</Kbd> to jump anywhere.
          </p>
        </Specimen>

        <Specimen label="Spec list and stats">
          <div className="ds-grid-2">
            <SpecList
              items={[
                {
                  label: "Workspace",
                  value: "unshell",
                  note: "~/Projects/personal",
                },
                { label: "Branch", value: "reset/empty-desktop" },
                { label: "Agent", value: "idle" },
              ]}
            />
            <StatGrid
              stats={[
                { value: "12", label: "Repos" },
                { value: "48", label: "Trees" },
                { value: "3", label: "Agents" },
                { value: "7", label: "Jobs" },
              ]}
            />
          </div>
        </Specimen>

        <Specimen label="Frame">
          <Frame caption="00 // Preview">
            <Display size="md" as="h3">
              Everything, already installed.
            </Display>
          </Frame>
        </Specimen>

        <Specimen label="Feature grid">
          <FeatureGrid
            items={[
              {
                glyph: "換",
                title: "Change anything.",
                body: "Swap tools per workspace without touching the others.",
              },
              {
                glyph: "家",
                title: "One home.",
                body: "Repos, trees and knowledge live side by side.",
              },
              {
                glyph: "人",
                title: "Nobody works alone.",
                body: "Agents share the same environment and history.",
              },
            ]}
          />
        </Specimen>

        <Specimen label="Accordion">
          <Accordion
            defaultOpen="what"
            items={[
              {
                id: "what",
                title: "What is Unshell?",
                content: "A development environment for people and agents.",
              },
              {
                id: "where",
                title: "Where does my data live?",
                content: "On your machine, inside each workspace.",
              },
              {
                id: "agents",
                title: "Which agents can I run?",
                content: "Any agent that speaks the harness protocol.",
              },
            ]}
          />
        </Specimen>
      </Block>
    </div>
  );
}
