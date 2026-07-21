/**
 * JSX/React Feature: Class Components (Legacy)
 * Class components, lifecycle methods, this.state, setState,
 * event binding patterns, error boundaries.
 *
 * Legacy but essential: parsers encounter millions of lines of this
 * style in existing codebases. Error boundaries STILL require classes.
 */
import React, { Component, PureComponent } from 'react';

// ── Basic class component ──────────────────────────────────────────────────
class Greeting extends Component {
  render() {
    return <h1>Hello, {this.props.name}!</h1>;
  }
}

// ── State via constructor ──────────────────────────────────────────────────
class ClassicCounter extends Component {
  constructor(props) {
    super(props);
    this.state = {
      count: props.initialCount ?? 0,
      lastChanged: null,
    };
    // The classic bind-in-constructor pattern
    this.handleIncrement = this.handleIncrement.bind(this);
  }

  handleIncrement() {
    // Functional setState with updater
    this.setState((prevState, props) => ({
      count: prevState.count + (props.step ?? 1),
      lastChanged: Date.now(),
    }));
  }

  // Class field arrow function — no binding needed (class fields + arrow)
  handleReset = () => {
    this.setState({ count: 0, lastChanged: Date.now() });
  };

  handleDecrement = () => {
    this.setState(prev => ({ count: prev.count - 1 }));
  };

  render() {
    const { count } = this.state;
    return (
      <div>
        <p>Count: {count}</p>
        <button onClick={this.handleIncrement}>+</button>
        <button onClick={this.handleDecrement}>-</button>
        <button onClick={this.handleReset}>Reset</button>
      </div>
    );
  }
}

// ── State as class field (no constructor) ──────────────────────────────────
class Toggle extends Component {
  state = { on: false };                          // class field state

  static defaultProps = { label: 'Toggle' };      // static class field

  flip = () => this.setState(s => ({ on: !s.on }));

  render() {
    return (
      <button onClick={this.flip} aria-pressed={this.state.on}>
        {this.props.label}: {this.state.on ? 'ON' : 'OFF'}
      </button>
    );
  }
}

// ── Full lifecycle methods ─────────────────────────────────────────────────
class DataFetcher extends Component {
  state = {
    data: null,
    loading: true,
    error: null,
  };

  componentDidMount() {
    // Runs once after first render — fetch, subscribe, timers
    this.fetchData();
    this.intervalId = setInterval(() => this.fetchData(), 30_000);
  }

  componentDidUpdate(prevProps, prevState) {
    // Runs after re-renders — compare to react to prop changes
    if (prevProps.resourceId !== this.props.resourceId) {
      this.setState({ loading: true });
      this.fetchData();
    }
  }

  componentWillUnmount() {
    // Cleanup — timers, subscriptions, aborts
    clearInterval(this.intervalId);
    this.aborted = true;
  }

  shouldComponentUpdate(nextProps, nextState) {
    // Performance escape hatch — skip renders
    return (
      nextProps.resourceId !== this.props.resourceId ||
      nextState.data !== this.state.data ||
      nextState.loading !== this.state.loading
    );
  }

  static getDerivedStateFromProps(props, state) {
    // Rarely-used: sync state from props before render
    if (props.resetSignal && state.data !== null) {
      return { data: null, loading: true };
    }
    return null;                     // no state change
  }

  getSnapshotBeforeUpdate(prevProps, prevState) {
    // Capture DOM info before it changes (e.g. scroll position)
    return { scrollY: typeof window !== 'undefined' ? window.scrollY : 0 };
  }

  async fetchData() {
    try {
      const response = await fetch(`/api/resource/${this.props.resourceId}`);
      const data = await response.json();
      if (!this.aborted) this.setState({ data, loading: false, error: null });
    } catch (error) {
      if (!this.aborted) this.setState({ error, loading: false });
    }
  }

  render() {
    const { data, loading, error } = this.state;
    if (loading) return <p>Loading resource {this.props.resourceId}…</p>;
    if (error) return <p>Error: {error.message}</p>;
    return <pre>{JSON.stringify(data, null, 2)}</pre>;
  }
}

// ── Error boundary — the pattern that REQUIRES a class ─────────────────────
class ErrorBoundary extends Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error) {
    // Render-phase: switch to fallback UI
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Commit-phase: log the error
    console.error('Boundary caught:', error.message, errorInfo?.componentStack);
  }

  handleRetry = () => this.setState({ hasError: false, error: null });

  render() {
    if (this.state.hasError) {
      return (
        <div role="alert" className="error-boundary">
          <h2>Something broke.</h2>
          <details>
            <summary>Details</summary>
            <pre>{this.state.error?.message}</pre>
          </details>
          <button onClick={this.handleRetry}>Try again</button>
        </div>
      );
    }
    return this.props.children;
  }
}

// ── PureComponent — shallow-compare optimization ───────────────────────────
class ExpensiveRow extends PureComponent {
  render() {
    const { item } = this.props;
    return (
      <tr>
        <td>{item.name}</td>
        <td>{item.value}</td>
      </tr>
    );
  }
}

// ── Controlled form — the classic class pattern ────────────────────────────
class ContactForm extends Component {
  state = { name: '', email: '', message: '', submitted: false };

  handleChange = (event) => {
    const { name, value } = event.target;
    this.setState({ [name]: value });            // computed property in setState
  };

  handleSubmit = (event) => {
    event.preventDefault();
    this.setState({ submitted: true }, () => {
      // setState callback — runs after state committed
      console.log('Submitted:', this.state);
    });
  };

  render() {
    if (this.state.submitted) {
      return <p>Thanks, {this.state.name}!</p>;
    }
    return (
      <form onSubmit={this.handleSubmit}>
        <input name="name" value={this.state.name} onChange={this.handleChange} placeholder="Name" />
        <input name="email" value={this.state.email} onChange={this.handleChange} placeholder="Email" type="email" />
        <textarea name="message" value={this.state.message} onChange={this.handleChange} rows={4} />
        <button type="submit">Send</button>
      </form>
    );
  }
}

// ── Composition ────────────────────────────────────────────────────────────
export default class App extends Component {
  render() {
    return (
      <ErrorBoundary>
        <Greeting name="Class Components" />
        <ClassicCounter initialCount={10} step={5} />
        <Toggle label="Dark mode" />
        <DataFetcher resourceId={1} />
        <table>
          <tbody>
            <ExpensiveRow item={{ name: 'metric', value: 42 }} />
          </tbody>
        </table>
        <ContactForm />
      </ErrorBoundary>
    );
  }
}
