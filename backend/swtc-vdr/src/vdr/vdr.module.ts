import { Module } from "@nestjs/common";
import { VdrService } from "./vdr.service";
import { VdrController } from "./vdr.controller";

@Module({
  controllers: [VdrController],
  providers: [VdrService],
})
export class VdrModule {}
