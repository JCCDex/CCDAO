<template>
    <div class="boxtwo">
        <p style="margin-left: 614px;margin-top: 80px;font-size: 50px;line-height: 50px;
        font-family: PingFangSC-Medium, sans-serif;">$CCDAO</p>
        <p style="margin-left: 628.5px;margin-top: 150px;font-size: 40px;line-height: 50px;
        font-family: PingFangSC-Semibold, sans-serif;">HOLDING</p>
        <div class="hold">
            <div class="holdbox">
                <img src="../assets/tag.svg" style="position: absolute;">
                <p style="margin-left: 160px;margin-top: 20px;font-size: 14px;line-height: 40px;
        font-family: PingFangSC-Semibold, sans-serif;">ETH chain Positions</p>
                <p style="margin-left: 160px;margin-top: 60px;font-size: 30px;
        font-family: PingFangSC-Semibold, sans-serif;">1000000CCDAO</p>
            </div>
            <div class="holdbox" style="margin-top:50px;">
                <img src="../assets/tag.svg" style="position: absolute;">
                <p style="margin-left: 160px;margin-top: 20px;font-size: 14px;line-height: 40px;
        font-family: PingFangSC-Semibold, sans-serif;"> SWTC chain Positions</p>
                <p style="margin-left: 160px;margin-top: 60px;font-size: 30px;
        font-family: PingFangSC-Semibold, sans-serif;">1000000CCDAO</p>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name:"Holds"
}
</script>

<style>
    .boxtwo{
        left: 0px;
        top: 901px;
        width: 1440px;
        height: 900px;
        position: absolute;
        background-image: url("../assets/bgimg2.svg");
    }
    .boxtwo p{
        width: 183px;
        height: 50px;
        mix-blend-mode: normal;
        color: rgba(255, 255, 255, 1);
        position: absolute;
    }
    .hold{
        margin-left: 420px;
        margin-top: 285px;
        width: 600px;
        height: 290px;
    }
    .holdbox{
        width: 600px;
        height: 120px;
        background: rgba(96.00000000000001, 194.00000000000006, 248, 1);
        background-blend-mode: normal;
        border-radius: 110px;
        mix-blend-mode: normal;
    }

</style>