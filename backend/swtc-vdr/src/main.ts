import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { Logger, ValidationPipe } from "@nestjs/common";
import { CommonResponse } from "./entities/response.entity";
import { AllExceptionsFilter } from "./exceptions/exceptions.filter";
import { TransformInterceptor } from "./transform/transform.interceptor";
import { WINSTON_MODULE_NEST_PROVIDER } from "nest-winston";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const options = new DocumentBuilder()
    .setTitle("SWTC DID VDR API")
    .setDescription("The SWTC DID VDR API")
    .setVersion("1.0")
    .addTag("SWTC DID VDR API")
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, options, {
    extraModels: [CommonResponse],
  });

  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
    }),
  );
  app.useLogger(app.get(WINSTON_MODULE_NEST_PROVIDER));

  SwaggerModule.setup("api", app, document);
  app.enableCors({
    origin: "*",
  });

  await app.listen(3000, async () => {
    Logger.log(`Application is running on: ${await app.getUrl()}`);
  });
}

bootstrap().catch((err) => {
  Logger.error("Error starting the application", err);
});
