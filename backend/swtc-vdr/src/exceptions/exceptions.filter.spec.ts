import { AllExceptionsFilter } from "./exceptions.filter";
import { ArgumentsHost, BadRequestException, HttpStatus } from "@nestjs/common";
import { ServiceException } from "../utils/service-error";
import { vi } from "vitest";

function createHttpHostMock(overrides?: { url?: string; method?: string }) {
  const res = {
    status: vi.fn().mockReturnThis(),
    json: vi.fn()
  };
  const req = {
    url: overrides?.url || "/test",
    method: overrides?.method || "GET"
  };
  const host: Partial<ArgumentsHost> = {
    // @ts-ignore
    switchToHttp: () => ({
      getResponse: () => res,
      getRequest: () => req
    }),
    // @ts-ignore
    getType: () => "http"
  };
  return { host: host as ArgumentsHost, res, req };
}

describe("ExceptionsFilter", () => {
  it("should be defined", () => {
    expect(new AllExceptionsFilter()).toBeDefined();
  });

  it("should handle exceptions", () => {
    const filter = new AllExceptionsFilter();
    const { host, res } = createHttpHostMock();
    const ex = new BadRequestException({ message: ["Invalid id"] });

    filter.catch(ex, host);
    expect(res.status).toHaveBeenCalledWith(HttpStatus.OK);

    const payload = res.json.mock.calls[0][0];

    expect(payload).toEqual({
      code: 400,
      message: "Invalid id"
    });
  });

  it("should handle error", () => {
    const filter = new AllExceptionsFilter();
    const { host, res } = createHttpHostMock();

    const ex = new Error("Some error");

    filter.catch(ex, host);
    expect(res.status).toHaveBeenCalledWith(HttpStatus.OK);

    const payload = res.json.mock.calls[0][0];

    expect(payload).toEqual({
      code: 500,
      message: "Some error"
    });
  });

  it("should handle service error", () => {
    const filter = new AllExceptionsFilter();
    const { host, res } = createHttpHostMock();

    const ex = new ServiceException(
      "Service unavailable",
      HttpStatus.SERVICE_UNAVAILABLE
    );

    filter.catch(ex, host);
    expect(res.status).toHaveBeenCalledWith(HttpStatus.OK);

    const payload = res.json.mock.calls[0][0];

    expect(payload).toEqual({
      code: 503,
      message: "Service unavailable"
    });
  });

  it("should catch string error", () => {
    const filter = new AllExceptionsFilter();
    const { host, res } = createHttpHostMock();

    const ex = "Some string error";

    filter.catch(ex, host);
    expect(res.status).toHaveBeenCalledWith(HttpStatus.OK);

    const payload = res.json.mock.calls[0][0];

    expect(payload).toEqual({
      code: 500,
      message: "Some string error"
    });
  });
});
