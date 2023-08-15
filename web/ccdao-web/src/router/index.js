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
  scrollBehavior(to, from, savedPosition) {
    // 如果有锚点，滚动到锚点位置
    if (to.hash) {
      return {
        selector: to.hash,
        behavior: "smooth", // 可选，平滑滚动效果
      };
    }
    // 如果之前已经滚动到某个位置，恢复到之前的位置
    if (savedPosition) {
      return savedPosition;
    }
    // 默认滚动到顶部
    return { x: 0, y: 0 };
  },
});

router.beforeEach((to, from, next) => {
  if (!to.name) {
    router.push("/");
  }
  next();
});

export default router;
