import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('ErrorBoundary 捕获到错误:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="card">
          <h2>组件加载失败</h2>
          <div className="error-message">
            <p>抱歉，组件加载时出现了错误。</p>
            <details>
              <summary>错误详情</summary>
              <pre>{this.state.error?.toString()}</pre>
            </details>
            <button 
              className="btn" 
              onClick={() => this.setState({ hasError: false, error: null })}
            >
              重试
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
