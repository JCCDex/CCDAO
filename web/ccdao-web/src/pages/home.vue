<template>
  <div class="roll">
    <Netalter></Netalter>
    <Wel></Wel>
    <Holds></Holds>
    <ToBuy></ToBuy>
    <WebAdd></WebAdd>
    <Member></Member>
    <Signers></Signers>
    <Connector></Connector>
  </div>
</template>

<script>
import Netalter from "../components/Netalter";
import Wel from "../components/Wel";
import Holds from "../components/Holds";
import ToBuy from "../components/ToBuy";
import WebAdd from "../components/WebAdd";
import Member from "../components/Member";
import Signers from "../components/Signers";
import Connector from "../components/Connector";

export default {
  name: "home",
  components: {
    Netalter,
    Wel,
    Holds,
    ToBuy,
    WebAdd,
    Member,
    Signers,
    Connector,
  },
};
</script>

<style></style>
