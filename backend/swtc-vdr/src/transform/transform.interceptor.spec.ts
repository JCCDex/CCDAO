import { lastValueFrom, of } from "rxjs";
import { TransformInterceptor } from "./transform.interceptor";
import { StreamableFile } from "@nestjs/common";

describe("TransformInterceptor", () => {
  function createExecutionContextMock(): any {
    return {
      // 如果拦截器里没用，就不需要实现细节
      switchToHttp: () => ({
        getRequest: () => ({ url: "/test", method: "GET" }),
        getResponse: () => ({})
      }),
      getClass: () => ({}),
      getHandler: () => ({}),
      getType: () => "http"
    } as any;
  }
  const ctx = createExecutionContextMock();
  const interceptor = new TransformInterceptor();
  it("should be defined", () => {
    expect(interceptor).toBeDefined();
  });

  it("should wrap data", async () => {
    const next = { handle: () => of({ id: 1 }) };

    const result$ = interceptor.intercept(ctx, next as any);
    const result = await lastValueFrom(result$);

    expect(result).toEqual({
      message: "success",
      data: { id: 1 },
      code: 0
    });
  });

  it("should pass through StreamableFile", async () => {
    const stream = new StreamableFile(Buffer.from("test"));
    const next = { handle: () => of(stream) };

    const result$ = interceptor.intercept(ctx, next as any);
    const result = await lastValueFrom(result$);

    expect(result).toBe(stream);
  });
});
