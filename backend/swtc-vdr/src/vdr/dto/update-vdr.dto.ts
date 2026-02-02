import { PartialType } from "@nestjs/swagger";
import { CreateVdrDto } from "./create-vdr.dto";

export class UpdateVdrDto extends PartialType(CreateVdrDto) {}
