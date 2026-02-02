import { readFileSync, existsSync } from "fs";
import * as yaml from "js-yaml";
import { join } from "path";

const isDev = process.env.NODE_ENV === "development";
const isE2E = process.env.NODE_ENV === "e2e";
const YAML_CONFIG_FILENAME = isDev
  ? ".dev.yaml"
  : isE2E
    ? ".e2e.yaml"
    : ".prod.yaml";

export default () => {
  let config = join(__dirname, YAML_CONFIG_FILENAME);
  if (!existsSync(config)) {
    config = join(__dirname, "../../config", YAML_CONFIG_FILENAME);
  }
  return yaml.load(readFileSync(config, "utf8")) as Record<string, any>;
};
