/**
 * JSX/React Feature: Conditional Rendering and List Rendering
 * Ternaries, && guards, early returns, .map() with keys,
 * nested lists, complex conditional composition.
 */
import React, { useState } from 'react';

// ── Ternary in JSX ─────────────────────────────────────────────────────────
function LoginStatus({ isLoggedIn, username }) {
  return (
    <div>
      {isLoggedIn ? (
        <p>Welcome back, {username}!</p>
      ) : (
        <p>Please sign in.</p>
      )}
    </div>
  );
}

// Nested ternaries (readable when formatted as a chain)
function TrafficLight({ color }) {
  return (
    <div className="light">
      {color === 'red' ? '🛑 Stop'
        : color === 'yellow' ? '⚠️ Slow'
        : color === 'green' ? '✅ Go'
        : '❓ Unknown'}
    </div>
  );
}

// ── && short-circuit rendering ─────────────────────────────────────────────
function Notifications({ count, messages }) {
  return (
    <div>
      {count > 0 && <span className="badge">{count}</span>}
      {messages.length > 0 && (
        <ul>
          {messages.map((msg, i) => <li key={i}>{msg}</li>)}
        </ul>
      )}
      {/* The classic 0-rendering bug: count && <X/> renders "0" when count=0 */}
      {/* Correct: use count > 0 or Boolean(count) */}
      {Boolean(count) && <p>You have notifications</p>}
    </div>
  );
}

// ── Early returns ──────────────────────────────────────────────────────────
function DataPanel({ loading, error, data }) {
  if (loading) {
    return <div className="spinner">Loading…</div>;
  }

  if (error) {
    return (
      <div className="error-panel">
        <h3>Something went wrong</h3>
        <pre>{error.message}</pre>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return <p className="empty">No data available.</p>;
  }

  return (
    <table>
      <tbody>
        {data.map(row => (
          <tr key={row.id}>
            <td>{row.name}</td>
            <td>{row.value}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// ── Null rendering (render nothing) ────────────────────────────────────────
function FeatureFlag({ enabled, children }) {
  if (!enabled) return null;          // valid — renders nothing
  return <>{children}</>;
}

// ── Lists with .map() and keys ─────────────────────────────────────────────
function TodoList({ todos }) {
  return (
    <ul className="todo-list">
      {todos.map(todo => (
        <li key={todo.id} className={todo.done ? 'done' : 'pending'}>
          <input type="checkbox" checked={todo.done} readOnly />
          <span>{todo.text}</span>
          {todo.priority === 'high' && <strong> (!)</strong>}
        </li>
      ))}
    </ul>
  );
}

// Index as key — only acceptable for static lists
function StaticSteps({ steps }) {
  return (
    <ol>
      {steps.map((step, index) => (
        <li key={index}>{step}</li>
      ))}
    </ol>
  );
}

// ── Nested lists ───────────────────────────────────────────────────────────
function CategoryTree({ categories }) {
  return (
    <ul className="category-tree">
      {categories.map(category => (
        <li key={category.id}>
          <strong>{category.name}</strong>
          {category.items.length > 0 && (
            <ul>
              {category.items.map(item => (
                <li key={item.id}>
                  {item.name} — ${item.price.toFixed(2)}
                  {item.tags.length > 0 && (
                    <span className="tags">
                      {item.tags.map(tag => (
                        <em key={tag} className="tag">#{tag} </em>
                      ))}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          )}
        </li>
      ))}
    </ul>
  );
}

// ── filter + map chains ────────────────────────────────────────────────────
function ActiveUserList({ users, minAge }) {
  return (
    <ul>
      {users
        .filter(u => u.active && u.age >= minAge)
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(({ id, name, age }) => (
          <li key={id}>
            {name}, {age}
          </li>
        ))}
    </ul>
  );
}

// ── Rendering object entries ───────────────────────────────────────────────
function ConfigTable({ config }) {
  return (
    <dl>
      {Object.entries(config).map(([key, value]) => (
        <React.Fragment key={key}>
          <dt>{key}</dt>
          <dd>{typeof value === 'boolean' ? (value ? 'yes' : 'no') : String(value)}</dd>
        </React.Fragment>
      ))}
    </dl>
  );
}

// ── Switch-style rendering with an object map ──────────────────────────────
function StatusPanel({ status }) {
  const panels = {
    idle:    <p>Waiting to start…</p>,
    running: <p className="running">Processing <span className="spinner" /></p>,
    done:    <p className="success">Completed ✓</p>,
    failed:  <p className="failure">Failed ✗ <button>Retry</button></p>,
  };

  return panels[status] ?? <p>Unknown status: {status}</p>;
}

// ── Full composition with state-driven conditionals ────────────────────────
export default function App() {
  const [tab, setTab] = useState('todos');
  const [showArchived, setShowArchived] = useState(false);

  const todos = [
    { id: 1, text: 'Test the parser', done: false, priority: 'high' },
    { id: 2, text: 'Write JSX samples', done: true, priority: 'normal' },
    { id: 3, text: 'Ship dataset', done: false, priority: 'normal' },
  ];

  const categories = [
    {
      id: 'c1',
      name: 'Electronics',
      items: [
        { id: 'i1', name: 'Keyboard', price: 79.99, tags: ['mechanical', 'rgb'] },
        { id: 'i2', name: 'Mouse', price: 49.5, tags: [] },
      ],
    },
    { id: 'c2', name: 'Empty Category', items: [] },
  ];

  const tabs = ['todos', 'categories', 'status'];

  return (
    <div className="app">
      <nav>
        {tabs.map(t => (
          <button
            key={t}
            className={tab === t ? 'tab active' : 'tab'}
            onClick={() => setTab(t)}
          >
            {t}
          </button>
        ))}
      </nav>

      {tab === 'todos' && (
        <>
          <TodoList todos={showArchived ? todos : todos.filter(t => !t.done)} />
          <label>
            <input
              type="checkbox"
              checked={showArchived}
              onChange={e => setShowArchived(e.target.checked)}
            />
            Show completed
          </label>
        </>
      )}

      {tab === 'categories' && <CategoryTree categories={categories} />}

      {tab === 'status' && (
        <>
          <StatusPanel status="running" />
          <StatusPanel status="mystery" />
        </>
      )}

      <FeatureFlag enabled={tab === 'todos'}>
        <p>Todo tips are enabled!</p>
      </FeatureFlag>

      <LoginStatus isLoggedIn username="Alice" />
      <TrafficLight color="green" />
      <Notifications count={0} messages={[]} />
      <DataPanel loading={false} error={null} data={[{ id: 1, name: 'row', value: 42 }]} />
      <StaticSteps steps={['Install', 'Configure', 'Run']} />
      <ActiveUserList
        users={[
          { id: 1, name: 'Zoe', age: 25, active: true },
          { id: 2, name: 'Adam', age: 17, active: true },
          { id: 3, name: 'Bea', age: 30, active: false },
        ]}
        minAge={18}
      />
      <ConfigTable config={{ darkMode: true, fontSize: 14, beta: false }} />
    </div>
  );
}
