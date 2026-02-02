import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from "@nestjs/common";
import { VdrService } from "./vdr.service";
import { CreateVdrDto } from "./dto/create-vdr.dto";
import { UpdateVdrDto } from "./dto/update-vdr.dto";
import { ApiTags } from "@nestjs/swagger";

@Controller("/v0/api/vdr")
@ApiTags("VDR")
export class VdrController {
  constructor(private readonly vdrService: VdrService) {}

  @Post()
  create(@Body() createVdrDto: CreateVdrDto) {
    return this.vdrService.create(createVdrDto);
  }

  @Get()
  findAll() {
    return this.vdrService.findAll();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.vdrService.findOne(+id);
  }

  @Patch(":id")
  update(@Param("id") id: string, @Body() updateVdrDto: UpdateVdrDto) {
    return this.vdrService.update(+id, updateVdrDto);
  }

  @Delete(":id")
  remove(@Param("id") id: string) {
    return this.vdrService.remove(+id);
  }
}
