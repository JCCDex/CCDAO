import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { Logger } from "@nestjs/common";

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private logger = new Logger();

  catch(exception: unknown, host: ArgumentsHost): void {
    // In certain situations `httpAdapter` might not be available in the
    // constructor method, thus we should resolve it here.
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message;
    if (exception instanceof BadRequestException) {
      const res = exception.getResponse() as any;
      message = Array.isArray(res?.message)
        ? res?.message?.[0]
        : res?.message || "Unknown error";
    } else if (exception instanceof Error) {
      message = exception.message;
    } else {
      message = exception;
    }

    const responseBody = {
      code: status,
      message,
    };

    if (
      process.env.NODE_ENV !== "e2e" &&
      process.env.NODE_ENV !== "test:unit"
    ) {
      this.logger.error(exception);
    }

    response.status(200).json(responseBody);
  }
}
