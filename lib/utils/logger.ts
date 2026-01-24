/**
 * Logging Infrastructure
 * Structured logging with multiple transports and log levels
 */

// ============================================
// TYPES
// ============================================

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

export interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: Date;
  context?: Record<string, any>;
  error?: Error;
  userId?: string;
  tenantId?: string;
  requestId?: string;
  component?: string;
}

export interface LoggerConfig {
  level: LogLevel;
  environment: string;
  enableConsole: boolean;
  enableFile: boolean;
  enableRemote: boolean;
  remoteEndpoint?: string;
}

// ============================================
// LOGGER CLASS
// ============================================

class Logger {
  private config: LoggerConfig;
  private logBuffer: LogEntry[] = [];
  private readonly MAX_BUFFER_SIZE = 100;

  constructor(config?: Partial<LoggerConfig>) {
    this.config = {
      level: this.getDefaultLogLevel(),
      environment: process.env.NODE_ENV || 'development',
      enableConsole: true,
      enableFile: false, // Disable by default (not supported in Edge runtime)
      enableRemote: process.env.NODE_ENV === 'production',
      remoteEndpoint: process.env.LOG_ENDPOINT,
      ...config,
    };
  }

  private getDefaultLogLevel(): LogLevel {
    const env = process.env.NODE_ENV;
    if (env === 'production') return LogLevel.INFO;
    if (env === 'test') return LogLevel.WARN;
    return LogLevel.DEBUG; // development
  }

  private shouldLog(level: LogLevel): boolean {
    return level >= this.config.level;
  }

  private formatMessage(entry: LogEntry): string {
    const { level, message, timestamp, context, component } = entry;
    const levelName = LogLevel[level];
    const time = timestamp.toISOString();
    const comp = component ? `[${component}]` : '';

    let formatted = `${time} ${levelName} ${comp} ${message}`;

    if (context && Object.keys(context).length > 0) {
      formatted += `\n${JSON.stringify(context, null, 2)}`;
    }

    if (entry.error) {
      formatted += `\n${entry.error.stack || entry.error.message}`;
    }

    return formatted;
  }

  private getConsoleMethod(level: LogLevel): 'log' | 'info' | 'warn' | 'error' {
    switch (level) {
      case LogLevel.DEBUG:
        return 'log';
      case LogLevel.INFO:
        return 'info';
      case LogLevel.WARN:
        return 'warn';
      case LogLevel.ERROR:
      case LogLevel.FATAL:
        return 'error';
      default:
        return 'log';
    }
  }

  private logToConsole(entry: LogEntry): void {
    if (!this.config.enableConsole) return;

    const method = this.getConsoleMethod(entry.level);
    const formatted = this.formatMessage(entry);

    // Color coding for different log levels (if supported)
    const colors: Record<LogLevel, string> = {
      [LogLevel.DEBUG]: '\x1b[36m', // Cyan
      [LogLevel.INFO]: '\x1b[32m', // Green
      [LogLevel.WARN]: '\x1b[33m', // Yellow
      [LogLevel.ERROR]: '\x1b[31m', // Red
      [LogLevel.FATAL]: '\x1b[35m', // Magenta
    };

    const reset = '\x1b[0m';
    const coloredMessage = `${colors[entry.level]}${formatted}${reset}`;

    console[method](coloredMessage);
  }

  private async logToRemote(entry: LogEntry): Promise<void> {
    if (!this.config.enableRemote || !this.config.remoteEndpoint) return;

    try {
      // Add to buffer
      this.logBuffer.push(entry);

      // Send when buffer is full
      if (this.logBuffer.length >= this.MAX_BUFFER_SIZE) {
        await this.flushLogs();
      }
    } catch (error) {
      // Fail silently for remote logging
      console.error('Failed to send logs to remote:', error);
    }
  }

  async flushLogs(): Promise<void> {
    if (this.logBuffer.length === 0) return;

    try {
      const logs = [...this.logBuffer];
      this.logBuffer = [];

      await fetch(this.config.remoteEndpoint!, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ logs }),
      });
    } catch (error) {
      console.error('Failed to flush logs:', error);
    }
  }

  private async log(
    level: LogLevel,
    message: string,
    context?: Record<string, any>,
    error?: Error
  ): Promise<void> {
    if (!this.shouldLog(level)) return;

    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date(),
      context,
      error,
    };

    // Console logging (synchronous)
    this.logToConsole(entry);

    // Remote logging (asynchronous)
    await this.logToRemote(entry);
  }

  // ============================================
  // PUBLIC API
  // ============================================

  debug(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  info(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, message, context);
  }

  warn(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.WARN, message, context);
  }

  error(message: string, error?: Error, context?: Record<string, any>): void {
    this.log(LogLevel.ERROR, message, context, error);
  }

  fatal(message: string, error?: Error, context?: Record<string, any>): void {
    this.log(LogLevel.FATAL, message, context, error);
  }

  // ============================================
  // CONTEXTUAL LOGGERS
  // ============================================

  /**
   * Create a child logger with additional context
   */
  child(context: Record<string, any>): ContextualLogger {
    return new ContextualLogger(this, context);
  }

  /**
   * Create logger for specific component
   */
  component(name: string): ContextualLogger {
    return new ContextualLogger(this, { component: name });
  }

  /**
   * Create logger for specific request
   */
  request(requestId: string, userId?: string, tenantId?: string): ContextualLogger {
    return new ContextualLogger(this, { requestId, userId, tenantId });
  }
}

// ============================================
// CONTEXTUAL LOGGER
// ============================================

class ContextualLogger {
  constructor(
    private parent: Logger,
    private context: Record<string, any>
  ) {}

  private mergeContext(additionalContext?: Record<string, any>): Record<string, any> {
    return { ...this.context, ...additionalContext };
  }

  debug(message: string, context?: Record<string, any>): void {
    this.parent.debug(message, this.mergeContext(context));
  }

  info(message: string, context?: Record<string, any>): void {
    this.parent.info(message, this.mergeContext(context));
  }

  warn(message: string, context?: Record<string, any>): void {
    this.parent.warn(message, this.mergeContext(context));
  }

  error(message: string, error?: Error, context?: Record<string, any>): void {
    this.parent.error(message, error, this.mergeContext(context));
  }

  fatal(message: string, error?: Error, context?: Record<string, any>): void {
    this.parent.fatal(message, error, this.mergeContext(context));
  }

  child(context: Record<string, any>): ContextualLogger {
    return new ContextualLogger(this.parent, this.mergeContext(context));
  }
}

// ============================================
// SINGLETON INSTANCE
// ============================================

const logger = new Logger();

export default logger;
export { logger, Logger, ContextualLogger };

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Measure execution time of async function
 */
export async function measureTime<T>(
  name: string,
  fn: () => Promise<T>
): Promise<T> {
  const start = Date.now();
  logger.debug(`${name} started`);

  try {
    const result = await fn();
    const duration = Date.now() - start;
    logger.debug(`${name} completed`, { duration: `${duration}ms` });
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    logger.error(`${name} failed`, error as Error, { duration: `${duration}ms` });
    throw error;
  }
}

/**
 * Log API request
 */
export function logRequest(
  method: string,
  url: string,
  statusCode: number,
  duration: number,
  context?: Record<string, any>
): void {
  const level = statusCode >= 500 ? LogLevel.ERROR : statusCode >= 400 ? LogLevel.WARN : LogLevel.INFO;

  const message = `${method} ${url} ${statusCode}`;

  if (level === LogLevel.ERROR) {
    logger.error(message, undefined, { method, url, statusCode, duration, ...context });
  } else if (level === LogLevel.WARN) {
    logger.warn(message, { method, url, statusCode, duration, ...context });
  } else {
    logger.info(message, { method, url, statusCode, duration, ...context });
  }
}

/**
 * Log database query
 */
export function logQuery(
  query: string,
  duration: number,
  rowCount?: number,
  params?: any[]
): void {
  logger.debug('Database query executed', {
    query,
    duration: `${duration}ms`,
    rowCount,
    params,
  });
}

/**
 * Log authentication event
 */
export function logAuth(
  event: 'login' | 'logout' | 'register' | 'verify' | 'failed',
  userId?: string,
  context?: Record<string, any>
): void {
  const message = `Auth: ${event}`;

  if (event === 'failed') {
    logger.warn(message, { userId, ...context });
  } else {
    logger.info(message, { userId, ...context });
  }
}

/**
 * Log payment transaction
 */
export function logPayment(
  event: 'initiated' | 'successful' | 'failed' | 'refunded',
  amount: number,
  reference: string,
  provider: string,
  context?: Record<string, any>
): void {
  const message = `Payment ${event}`;

  if (event === 'failed') {
    logger.error(message, undefined, { amount, reference, provider, ...context });
  } else {
    logger.info(message, { amount, reference, provider, ...context });
  }
}

/**
 * Log business event
 */
export function logEvent(
  event: string,
  context?: Record<string, any>
): void {
  logger.info(`Event: ${event}`, context);
}

/**
 * Log performance metrics
 */
export function logMetric(
  metric: string,
  value: number,
  unit: string = 'ms',
  context?: Record<string, any>
): void {
  logger.debug(`Metric: ${metric}`, { value, unit, ...context });
}

// ============================================
// INTEGRATION HELPERS
// ============================================

/**
 * Configure logger for production
 */
export function configureProductionLogger(config: {
  remoteEndpoint: string;
  level?: LogLevel;
}): void {
  const productionLogger = new Logger({
    level: config.level || LogLevel.INFO,
    environment: 'production',
    enableConsole: false,
    enableRemote: true,
    remoteEndpoint: config.remoteEndpoint,
  });

  // Replace singleton
  Object.assign(logger, productionLogger);
}

/**
 * Flush all pending logs (call before app shutdown)
 */
export async function flushLogs(): Promise<void> {
  await logger.flushLogs();
}
