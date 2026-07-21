/**
 * JSX Feature: Basic Syntax
 * Elements, attributes, expression containers, fragments, comments.
 *
 * ⚠ PARSER TEST CASE: JSX is NOT ECMAScript. A spec-compliant JS parser
 * must REJECT this file. Only parsers with the JSX extension (Babel,
 * esbuild, swc, TypeScript in .tsx mode) should accept it.
 */
import React from 'react';

// ── Basic elements ─────────────────────────────────────────────────────────
const simple = <div>Hello, JSX!</div>;

const withAttributes = <input type="text" placeholder="Enter name" maxLength={50} />;

// Self-closing tags are REQUIRED for void elements
const selfClosing = <br />;
const image = <img src="/logo.png" alt="Logo" width={200} height={100} />;

// ── Expression containers { } ──────────────────────────────────────────────
const name = 'World';
const greeting = <h1>Hello, {name}!</h1>;

const a = 6, b = 7;
const math = <p>The answer is {a * b}</p>;

const ternary = <span>{a > 5 ? 'big' : 'small'}</span>;

const methodCall = <p>{name.toUpperCase()} has {name.length} letters</p>;

// Template literal inside expression container
const nested = <div title={`User: ${name}`}>{`Welcome, ${name}`}</div>;

// ── Attribute forms ────────────────────────────────────────────────────────
const stringAttr    = <div className="container" />;          // string literal
const exprAttr      = <div tabIndex={0} />;                   // expression
const boolShorthand = <input disabled />;                     // true shorthand
const boolExplicit  = <input disabled={false} />;
const dataAttr      = <div data-testid="main-panel" data-index={3} />;
const ariaAttr      = <button aria-label="Close" aria-pressed={true} />;

// Spread attributes
const commonProps = { className: 'btn', role: 'button', tabIndex: 0 };
const spreadElement = <div {...commonProps} id="unique" />;

// Spread with override ordering (later wins)
const overridden = <div {...commonProps} className="btn-primary" />;

// ── style attribute takes an object ────────────────────────────────────────
const styled = (
  <div
    style={{
      backgroundColor: 'navy',       // camelCase, not kebab-case
      color: 'white',
      padding: '1rem',
      borderRadius: 8,               // numbers become px
      display: 'flex',
    }}
  >
    Styled content
  </div>
);

// ── Fragments ──────────────────────────────────────────────────────────────
// Short syntax <>...</>
const shortFragment = (
  <>
    <h2>Title</h2>
    <p>No wrapper div needed</p>
  </>
);

// Long syntax — required when you need a key
const items = ['alpha', 'beta', 'gamma'];
const keyedFragments = items.map(item => (
  <React.Fragment key={item}>
    <dt>{item}</dt>
    <dd>Description of {item}</dd>
  </React.Fragment>
));

// ── Nesting and children ───────────────────────────────────────────────────
const nestedTree = (
  <article className="post">
    <header>
      <h1>Post Title</h1>
      <time dateTime="2024-03-15">March 15, 2024</time>
    </header>
    <section>
      <p>
        First paragraph with <strong>bold</strong> and <em>italic</em> text,
        plus a <a href="/link">link</a>.
      </p>
      <ul>
        <li>Point one</li>
        <li>Point two</li>
      </ul>
    </section>
    <footer>
      <small>© 2024</small>
    </footer>
  </article>
);

// ── JSX comments ───────────────────────────────────────────────────────────
const withComments = (
  <div>
    {/* This is a JSX comment — expression container + block comment */}
    <p>Visible content</p>
    {/* Multi-line
        JSX comment */}
  </div>
);

// ── Entities and special characters ───────────────────────────────────────
const entities = (
  <p>
    Copyright &copy; 2024 &mdash; &ldquo;quoted&rdquo; &amp; more.
    Braces need escapes: {'{'} and {'}'}
    Less-than in text: {'<'} not-a-tag {'>'}
  </p>
);

// ── JSX is an expression — usable anywhere expressions go ─────────────────
function getBadge(status) {
  if (status === 'active') return <span className="badge green">Active</span>;
  if (status === 'idle') return <span className="badge yellow">Idle</span>;
  return <span className="badge gray">Offline</span>;
}

const badges = ['active', 'idle', 'offline'].map(getBadge);

const inArray = [<td key="1">Cell 1</td>, <td key="2">Cell 2</td>];

const inObject = {
  header: <h1>Header</h1>,
  body: <main>Body</main>,
};

// JSX in ternaries and logical expressions
const isLoggedIn = true;
const conditionalJsx = isLoggedIn ? <p>Welcome back!</p> : <p>Please log in.</p>;
const guarded = isLoggedIn && <button>Logout</button>;

// ── Member expression tags and dotted components ───────────────────────────
const UI = {
  Card: ({ children }) => <div className="card">{children}</div>,
  Button: ({ children }) => <button className="ui-btn">{children}</button>,
};

const dotted = (
  <UI.Card>
    <UI.Button>Click me</UI.Button>
  </UI.Card>
);

export default function App() {
  return (
    <>
      {greeting}
      {nestedTree}
      {shortFragment}
      <dl>{keyedFragments}</dl>
      {badges}
      {dotted}
      {conditionalJsx}
    </>
  );
}
