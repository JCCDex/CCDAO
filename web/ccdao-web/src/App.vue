<template>
  <div id="app">
    <Sidebar></Sidebar>
    <Header></Header>
    <router-view></router-view>
    <Foot></Foot>
  </div>
</template>

<script>
import Sidebar from "./components/Sidebar";
import Header from "./components/Header";
import Foot from "./components/Foot";

export default {
  components: {
    Sidebar,
    Header,
    Foot,
  },
};
</script>

<style>
#app {
  display: flex;
  height: 100%;
  flex-direction: column;
  justify-content: space-between;
  font-family: PingFangSC-Medium, sans-serif;
}

#app .roll {
  flex: 1;
  width: 100%;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  height: auto;
}
html {
  height: 100%;
}
body {
  margin: 0px;
  padding: 0px;
  height: 100%;
  overflow: hidden;
}
</style>
