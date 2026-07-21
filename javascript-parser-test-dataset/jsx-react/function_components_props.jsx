/**
 * JSX/React Feature: Function Components and Props
 * Props destructuring, defaults, children, spread props,
 * component composition, render props.
 */
import React from 'react';

// ── Basic function component ───────────────────────────────────────────────
function Welcome(props) {
  return <h1>Hello, {props.name}!</h1>;
}

// ── Props destructuring in parameters (the standard style) ────────────────
function UserCard({ name, email, role }) {
  return (
    <div className="user-card">
      <h3>{name}</h3>
      <p>{email}</p>
      <span className={`role role-${role}`}>{role}</span>
    </div>
  );
}

// ── Default prop values via destructuring defaults ─────────────────────────
function Button({ label = 'Click', variant = 'primary', size = 'medium', onClick }) {
  return (
    <button className={`btn btn-${variant} btn-${size}`} onClick={onClick}>
      {label}
    </button>
  );
}

// ── Rest props pattern ─────────────────────────────────────────────────────
function Input({ label, error, ...inputProps }) {
  return (
    <div className="form-field">
      <label>{label}</label>
      <input {...inputProps} className={error ? 'input-error' : 'input'} />
      {error && <span className="error-text">{error}</span>}
    </div>
  );
}

// ── children prop ──────────────────────────────────────────────────────────
function Card({ title, children }) {
  return (
    <div className="card">
      {title && <div className="card-header">{title}</div>}
      <div className="card-body">{children}</div>
    </div>
  );
}

// Multiple named "slots" via props (children alternative)
function Layout({ header, sidebar, children, footer }) {
  return (
    <div className="layout">
      <header className="layout-header">{header}</header>
      <div className="layout-middle">
        <aside className="layout-sidebar">{sidebar}</aside>
        <main className="layout-content">{children}</main>
      </div>
      <footer className="layout-footer">{footer}</footer>
    </div>
  );
}

// ── Arrow function components ──────────────────────────────────────────────
const Badge = ({ count }) => <span className="badge">{count > 99 ? '99+' : count}</span>;

const Divider = () => <hr className="divider" />;

// Implicit return with parens for multi-line
const Avatar = ({ src, alt, size = 40 }) => (
  <img
    className="avatar"
    src={src}
    alt={alt}
    width={size}
    height={size}
    style={{ borderRadius: '50%' }}
  />
);

// ── Component composition ──────────────────────────────────────────────────
function UserProfile({ user }) {
  return (
    <Card title={user.name}>
      <Avatar src={user.avatarUrl} alt={user.name} size={64} />
      <UserCard name={user.name} email={user.email} role={user.role} />
      <Badge count={user.notifications} />
    </Card>
  );
}

// ── Render props pattern ───────────────────────────────────────────────────
function DataProvider({ data, render }) {
  const processed = data.map(d => ({ ...d, processed: true }));
  return <div className="provider">{render(processed)}</div>;
}

// children-as-function variant
function MousePosition({ children }) {
  const position = { x: 100, y: 200 };   // would come from state in real code
  return children(position);
}

// ── Conditional component selection ────────────────────────────────────────
function StatusIcon({ status }) {
  const icons = {
    success: () => <span className="icon-check">✓</span>,
    error:   () => <span className="icon-x">✗</span>,
    pending: () => <span className="icon-spinner">◌</span>,
  };
  const Icon = icons[status] ?? icons.pending;
  return <Icon />;
}

// Dynamic component via capitalized variable — JSX resolution rule
function Heading({ level = 1, children }) {
  const Tag = `h${Math.min(6, Math.max(1, level))}`;   // 'h1'..'h6'
  return <Tag className="heading">{children}</Tag>;
}

// ── Full app composing everything ──────────────────────────────────────────
export default function App() {
  const user = {
    name: 'Alice Johnson',
    email: 'alice@example.com',
    role: 'admin',
    avatarUrl: '/avatars/alice.png',
    notifications: 142,
  };

  const products = [
    { id: 1, name: 'Widget' },
    { id: 2, name: 'Gadget' },
  ];

  return (
    <Layout
      header={<Heading level={1}>Dashboard</Heading>}
      sidebar={<nav>Navigation here</nav>}
      footer={<small>Footer content</small>}
    >
      <Welcome name={user.name} />
      <UserProfile user={user} />

      <Button label="Save" onClick={() => console.log('saved')} />
      <Button label="Cancel" variant="secondary" size="small" />
      <Button />

      <Input
        label="Email"
        type="email"
        placeholder="you@example.com"
        required
        error={null}
      />

      <Divider />

      <DataProvider
        data={products}
        render={(items) => (
          <ul>
            {items.map(item => <li key={item.id}>{item.name}</li>)}
          </ul>
        )}
      />

      <MousePosition>
        {({ x, y }) => <p>Mouse at ({x}, {y})</p>}
      </MousePosition>

      <StatusIcon status="success" />
      <StatusIcon status="error" />
      <StatusIcon status="unknown" />
    </Layout>
  );
}
