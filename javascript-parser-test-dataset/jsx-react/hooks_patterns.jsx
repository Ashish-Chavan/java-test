/**
 * JSX/React Feature: Hooks Patterns
 * useState, useEffect, useMemo, useCallback, useRef, useReducer,
 * custom hooks — the shape of modern React files.
 */
import React, {
  useState,
  useEffect,
  useMemo,
  useCallback,
  useRef,
  useReducer,
} from 'react';

// ── useState ──────────────────────────────────────────────────────────────
function Counter() {
  const [count, setCount] = useState(0);
  const [step, setStep] = useState(1);

  return (
    <div>
      <p>Count: {count}</p>
      {/* Functional update form */}
      <button onClick={() => setCount(c => c + step)}>+{step}</button>
      <button onClick={() => setCount(c => c - step)}>-{step}</button>
      <button onClick={() => setCount(0)}>Reset</button>
      <input
        type="number"
        value={step}
        onChange={e => setStep(Number(e.target.value))}
      />
    </div>
  );
}

// useState with object state and lazy initializer
function FormState() {
  const [form, setForm] = useState(() => ({
    name: '',
    email: '',
    subscribed: false,
  }));

  const updateField = (field, value) =>
    setForm(prev => ({ ...prev, [field]: value }));

  return (
    <form>
      <input
        value={form.name}
        onChange={e => updateField('name', e.target.value)}
        placeholder="Name"
      />
      <input
        value={form.email}
        onChange={e => updateField('email', e.target.value)}
        placeholder="Email"
      />
      <label>
        <input
          type="checkbox"
          checked={form.subscribed}
          onChange={e => updateField('subscribed', e.target.checked)}
        />
        Subscribe
      </label>
    </form>
  );
}

// ── useEffect ──────────────────────────────────────────────────────────────
function UserLoader({ userId }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;              // cleanup guard pattern
    setLoading(true);
    setError(null);

    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => {
        if (!cancelled) {
          setUser(data);
          setLoading(false);
        }
      })
      .catch(err => {
        if (!cancelled) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => { cancelled = true; };   // cleanup function
  }, [userId]);                            // dependency array

  if (loading) return <p>Loading…</p>;
  if (error) return <p className="error">Error: {error}</p>;
  return <div>Loaded: {user?.name}</div>;
}

// Effect with subscription + cleanup
function WindowSize() {
  const [size, setSize] = useState({ width: 0, height: 0 });

  useEffect(() => {
    const handler = () =>
      setSize({ width: window.innerWidth, height: window.innerHeight });

    handler();                              // initial read
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);                                    // empty deps: mount/unmount only

  return <p>{size.width} × {size.height}</p>;
}

// ── useMemo and useCallback ────────────────────────────────────────────────
function ExpensiveList({ items, filter }) {
  // Memoized derived data — recomputes only when deps change
  const filtered = useMemo(
    () => items.filter(item => item.name.toLowerCase().includes(filter.toLowerCase())),
    [items, filter]
  );

  const stats = useMemo(() => ({
    total: filtered.length,
    avgPrice: filtered.reduce((sum, i) => sum + i.price, 0) / (filtered.length || 1),
  }), [filtered]);

  // Memoized callback — stable identity across renders
  const handleSelect = useCallback((id) => {
    console.log(`selected item ${id}`);
  }, []);

  return (
    <div>
      <p>{stats.total} items, avg ${stats.avgPrice.toFixed(2)}</p>
      <ul>
        {filtered.map(item => (
          <li key={item.id} onClick={() => handleSelect(item.id)}>
            {item.name} — ${item.price}
          </li>
        ))}
      </ul>
    </div>
  );
}

// ── useRef ─────────────────────────────────────────────────────────────────
function FocusInput() {
  const inputRef = useRef(null);            // DOM ref
  const renderCount = useRef(0);            // mutable value that survives renders

  renderCount.current += 1;

  return (
    <div>
      <input ref={inputRef} placeholder="Click button to focus me" />
      <button onClick={() => inputRef.current?.focus()}>Focus</button>
      <small>Renders: {renderCount.current}</small>
    </div>
  );
}

// ── useReducer ─────────────────────────────────────────────────────────────
const initialCart = { items: [], total: 0 };

function cartReducer(state, action) {
  switch (action.type) {
    case 'add':
      return {
        items: [...state.items, action.item],
        total: state.total + action.item.price,
      };
    case 'remove': {
      const item = state.items.find(i => i.id === action.id);
      return {
        items: state.items.filter(i => i.id !== action.id),
        total: state.total - (item?.price ?? 0),
      };
    }
    case 'clear':
      return initialCart;
    default:
      throw new Error(`Unknown action: ${action.type}`);
  }
}

function ShoppingCart() {
  const [cart, dispatch] = useReducer(cartReducer, initialCart);

  return (
    <div>
      <p>Total: ${cart.total.toFixed(2)} ({cart.items.length} items)</p>
      <button onClick={() => dispatch({ type: 'add', item: { id: Date.now(), name: 'Widget', price: 9.99 } })}>
        Add Widget
      </button>
      <button onClick={() => dispatch({ type: 'clear' })}>Clear</button>
      <ul>
        {cart.items.map(item => (
          <li key={item.id}>
            {item.name}
            <button onClick={() => dispatch({ type: 'remove', id: item.id })}>×</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

// ── Custom hooks ───────────────────────────────────────────────────────────
function useToggle(initial = false) {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue(v => !v), []);
  return [value, toggle];
}

function useDebounce(value, delayMs = 300) {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}

function useLocalList(initial = []) {
  const [list, setList] = useState(initial);
  return {
    list,
    add: useCallback(item => setList(l => [...l, item]), []),
    remove: useCallback(index => setList(l => l.filter((_, i) => i !== index)), []),
    clear: useCallback(() => setList([]), []),
  };
}

function SearchBox() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 500);
  const [showFilters, toggleFilters] = useToggle();
  const { list: history, add: addToHistory } = useLocalList();

  useEffect(() => {
    if (debouncedQuery) addToHistory(debouncedQuery);
  }, [debouncedQuery, addToHistory]);

  return (
    <div>
      <input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search…" />
      <button onClick={toggleFilters}>{showFilters ? 'Hide' : 'Show'} filters</button>
      {showFilters && <div className="filters">Filter options here</div>}
      <p>Searching for: {debouncedQuery || '(nothing)'}</p>
      <small>History: {history.join(', ')}</small>
    </div>
  );
}

export default function App() {
  return (
    <>
      <Counter />
      <FormState />
      <UserLoader userId={1} />
      <WindowSize />
      <ExpensiveList items={[{ id: 1, name: 'Widget', price: 9.99 }]} filter="" />
      <FocusInput />
      <ShoppingCart />
      <SearchBox />
    </>
  );
}
