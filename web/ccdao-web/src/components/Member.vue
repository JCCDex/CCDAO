<template>
<div class="boxfive">
    <div class='memberbox'>
      <div class="memberdiv">
        <div class="membertag">
          <p class="texthint" style="left: 50px;top: 5px;font-size: 16px;line-height: 40px;">My CCDAO Amount</p>
          <p class="text" style="left: 50px;top: 30px;">2000000CCDAO</p>
          <p class="texthint" style="left: 370px;top: 40px;font-size: 14px;">status:</p>
          <p class="text" style="left: 420px;top: 34px;font-size: 14px;">YES</p>
          <img src="../assets/member.svg" style="position: absolute;right: 0px;">
        </div>
        <a href="">
          <p class="mrtext">Membership Requirements</p>
          <img src="../assets/buyarrow.svg" class="mrimg">
        </a>
        <p class="outtext">$CCDAO Member need to hold 10000CCDAO at least.</p>
      </div>
    </div>

  <img src="../assets/bgimg5.svg" style="width: 100%;position: relative; z-index: -1;"> 
</div>
  
</template>

<script>
export default {
    name:'Member'
}
</script>

<style>
.boxfive{
    width: 100%;
    mix-blend-mode: normal;
    position: relative;
}
.memberbox{
    display: flex;
    justify-content: center;
}
.memberdiv{
  position: absolute;
  top: 31%;
  width: 723px;
  height: 313px;
}
.membertag{
  position: relative;
  width: 600px;
  height: 120px;
  background: rgba(255, 255, 255, 1);
  background-blend-mode: normal;
  box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
  border-radius: 80px;
  mix-blend-mode: normal;
}
.texthint{
  background-blend-mode: normal;
  mix-blend-mode: normal;
  color: rgba(161, 166, 169, 1);
  font-family: PingFangSC-Medium, sans-serif;
}
.text{
  background-blend-mode: normal;
  mix-blend-mode: normal;
  color: rgba(73, 170, 239, 1);
  font-size: 30px;
  line-height: 30px;
  font-family: PingFangSC-Medium, sans-serif;
}
.mrtext{
  left: 10px;
  top: 200px;
  width: 241px;
  height: 20px;
  mix-blend-mode: normal;
  color: rgba(61, 61, 59, 1);
  font-size: 20px;
  line-height: 20px;
  font-family: PingFangSC-Medium, sans-serif;
}
.mrimg{
  position: absolute;
  left: 270px;
  top: 225px;
  width: 16.01px;
  height: 14.09px;
  background-blend-mode: normal;
  mix-blend-mode: normal;
}
.outtext{
  white-space: nowrap;
  position: absolute;
  left: 10px;
  top: 240px;
  width: 711px;
  height: 20px;
  mix-blend-mode: normal;
  color: rgba(61, 61, 59, 1);
  font-size: 30px;
  line-height: 20px;
  font-family: PingFangSC-Medium, sans-serif;
}
</style>