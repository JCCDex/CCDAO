<template>
  <div id="app">
    <Header></Header>
    <Wel></Wel>
    <Holds></Holds>
    <ToBuy></ToBuy>
    <WebAdd></WebAdd>
    <Member></Member>
    <Create></Create>
    <Foot></Foot>
  </div>
</template>

<script>
import Header from "./components/Header"
import Wel from "./components/Wel"
import Holds from "./components/Holds"
import ToBuy from "./components/ToBuy"
import WebAdd from "./components/WebAdd"
import Member from "./components/Member"
import Create from "./components/Create"
import Foot from "./components/Foot"

export default {
  components:{
    Header,
    Wel,
    Holds,
    ToBuy,
    WebAdd,
    Member,
    Create,
    Foot
  }
}
</script>

<style>
.app{
  width: 100%;
  height: 100%;
}
</style>
