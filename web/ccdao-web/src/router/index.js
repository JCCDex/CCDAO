import Vue from "vue";
import VueRouter from "vue-router";
import _import from "./import-component";

const originalPush = VueRouter.prototype.push;
VueRouter.prototype.push = function push(location, onResolve, onReject) {
  if (onResolve || onReject) return originalPush.call(this, location, onResolve, onReject);
  return originalPush.call(this, location).catch((err) => err);
};

Vue.use(VueRouter);

const routes = [
  {
    path: "/",
    name: "home",
    component: _import("home"),
  },
  {
    path: "/connector/:type",
    name: "showTerm",
    component: _import("showTerm"),
  },
];

const router = new VueRouter({
  routes,
});

router.beforeEach((to, from, next) => {
  if (!to.name) {
    next("/");
  } else {
    next();
  }
});

export default router;
