import { Test, TestingModule } from '@nestjs/testing';
import { VdrController } from './vdr.controller';
import { VdrService } from './vdr.service';

describe('VdrController', () => {
  let controller: VdrController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VdrController],
      providers: [VdrService],
    }).compile();

    controller = module.get<VdrController>(VdrController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
