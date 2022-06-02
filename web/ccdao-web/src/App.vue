<template>
  <div id="app">
    <Header></Header>
    <div class="roll">
      <Netalter></Netalter>
      <Wel></Wel>
      <Holds></Holds>
      <ToBuy></ToBuy>
      <WebAdd></WebAdd>
      <Member></Member>
      <Signers></Signers>
    </div>
    <Foot></Foot>
  </div>
</template>

<script>
import Netalter from "./components/Netalter";
import Header from "./components/Header";
import Wel from "./components/Wel";
import Holds from "./components/Holds";
import ToBuy from "./components/ToBuy";
import WebAdd from "./components/WebAdd";
import Member from "./components/Member";
import Signers from "./components/Signers";
import Foot from "./components/Foot";

export default {
  components: {
    Netalter,
    Header,
    Wel,
    Holds,
    ToBuy,
    WebAdd,
    Member,
    Signers,
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
