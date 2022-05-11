<template>
  <div id="app">
    <Header></Header>
    <Wel></Wel>
    <Holds></Holds>
    <ToBuy></ToBuy>
    <WebAdd></WebAdd>
    <Member></Member>
    <Signers></Signers>
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
import Signers from "./components/Signers"
import Foot from "./components/Foot"
import { JingchangWallet } from 'jcc_wallet'

export default {
  components:{
    Header,
    Wel,
    Holds,
    ToBuy,
    WebAdd,
    Member,
    Signers,
    Foot
  },

}
</script>

<style>
body{
  margin: 0px;
  padding: 0px;
}
.app{
  width: 100%;
  height: 100%;
}
</style>
