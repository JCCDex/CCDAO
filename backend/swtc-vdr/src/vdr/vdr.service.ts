import { Injectable } from "@nestjs/common";
import { CreateVdrDto } from "./dto/create-vdr.dto";
import { UpdateVdrDto } from "./dto/update-vdr.dto";

@Injectable()
export class VdrService {
  create(createVdrDto: CreateVdrDto) {
    console.log("createVdrDto", createVdrDto);
    return "This action adds a new vdr";
  }

  findAll() {
    return `This action returns all vdr`;
  }

  findOne(id: number) {
    return `This action returns a #${id} vdr`;
  }

  update(id: number, updateVdrDto: UpdateVdrDto) {
    console.log("updateVdrDto", updateVdrDto);
    return `This action updates a #${id} vdr`;
  }

  remove(id: number) {
    return `This action removes a #${id} vdr`;
  }
}
