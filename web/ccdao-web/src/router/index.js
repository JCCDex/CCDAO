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
    path: "/connector/TermOfService",
    name: "termOfService",
    component: _import("termOfService/index"),
  },
  {
    path: "/connector/TermOfService/:lang",
    name: "termOfService",
    component: _import("termOfService/index"),
  },
  {
    path: "/connector/PrivacyPolicy",
    name: "privacyPolicy",
    component: _import("privacyPolicy/index"),
  },
  {
    path: "/connector/PrivacyPolicy/:lang",
    name: "privacyPolicy",
    component: _import("privacyPolicy/index"),
  },
];

const router = new VueRouter({
  routes,
});

router.beforeEach((to, from, next) => {
  if (!to.name && !to.hash) {
    next({ path: "/", hash: to.path.replace("/", "#") });
  } else {
    next();
  }
});

export default router;
