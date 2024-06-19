jest.mock("./src/constants/env.constants.ts", () => ({
  ENVIRONMENT: "development",
  PROD: false,
}))
