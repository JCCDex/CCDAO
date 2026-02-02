import { Test, TestingModule } from '@nestjs/testing';
import { VdrService } from './vdr.service';

describe('VdrService', () => {
  let service: VdrService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [VdrService],
    }).compile();

    service = module.get<VdrService>(VdrService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
