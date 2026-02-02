import { Module, NestModule, MiddlewareConsumer } from "@nestjs/common";
import configuration from "./config/configuration";
import { ConfigModule } from "@nestjs/config";
import { WinstonModule } from "nest-winston";
import { LoggerMiddleware } from "./middleware/logger.middleware";
import winstonLogger from "./winston.config";
import { ScheduleModule } from "@nestjs/schedule";
import { VdrModule } from "./vdr/vdr.module";

@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule.forRoot({
      load: [configuration],
      isGlobal: true,
    }),
    WinstonModule.forRoot({
      transports: winstonLogger.transports,
      format: winstonLogger.format,
      defaultMeta: winstonLogger.defaultMeta,
      exitOnError: false, // 防止意外退出
    }),
    VdrModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes("*");
  }
}
