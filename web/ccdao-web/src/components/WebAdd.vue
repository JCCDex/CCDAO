<template>
  <div class="boxfour">
      <a name=WebAdd></a>
      <p class="addtext">On-chain contract address</p>
      <img src="../assets/addtext.svg" class="addtextimg">
      <div class="addbox" style="left: 272px;top: 342.5px;">
          <img src="../assets/addimg.png" class="addimg">
          <p class="addboxtext1" style="left: 42px;top: 2px;">ETH</p>
          <a href="">
              <img src="../assets/rightarrow.svg" class="right">
          </a>
      </div>
      <div class="addbox" style="left: 272px;top: 443px;">
          <img src="../assets/addimg.png" class="addimg">
          <p class="addboxtext1" style="left: 28px;top: 2px;">CCDAO</p>
          <a href="">
              <img src="../assets/rightarrow.svg" class="right">
          </a>
      </div>

      <img src="../assets/bgimg4.svg" style="width: 100%;position: relative; z-index: -1;display: flex;"> 
  </div>
</template>

<script>
export default {
    name:'WebAdd'
}
</script>

<style>
.boxfour{
    width: 100%;
    mix-blend-mode: normal;
    position: relative;
}
.addtext{
    left: 272px;
    top: 173px;
    width: 592px;
    height: 40px;
    mix-blend-mode: normal;
    color: rgba(255, 255, 255, 1);
    font-size: 46px;
    line-height: 40px;
}
.addtextimg{
    position: absolute;
    left: 882px;
    top: 220px;
    width: 36px;
    height: 36px;
}
.addbox{
    position: absolute;
    width: 580px;
    height: 60px;
    background: rgba(108.55350000000001, 197.289675, 252.45, 1);
    background-blend-mode: normal;
    border-radius: 60px;
    mix-blend-mode: normal;
}
.addimg{
    width: 120px;
    height: 60px;
    background-blend-mode: normal;
    border-radius: NaNpx;
    mix-blend-mode: normal;
}
.addboxtext1{
    position: absolute;
    width: 36px;
    height: 25px;
    mix-blend-mode: normal;
    color: rgba(51, 147, 230, 1);
    font-size: 18px;
}
.right{
    position: absolute;
    left: 546px;
    top: 25px;
    width: 14px;
    height: 10.5px;
    background-blend-mode: normal;
    mix-blend-mode: normal;
}

</style>