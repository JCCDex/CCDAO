const _import = (file) => () => import("@/pages/" + file + ".vue");

export default _import;
