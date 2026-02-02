import { HttpException } from "@nestjs/common";

export class ServiceException extends HttpException {
  constructor(message: string, statusCode: number) {
    super(message, statusCode);
  }
}
