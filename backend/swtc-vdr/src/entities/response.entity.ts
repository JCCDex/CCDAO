import { ApiProperty } from "@nestjs/swagger";

export class CommonResponse<T> {
  @ApiProperty({
    required: true,
    description: "状态码, 0表示成功, 其他表示失败",
    example: 0,
  })
  code: number;

  @ApiProperty()
  message: string;

  @ApiProperty({
    required: false,
  })
  data: T;
}
