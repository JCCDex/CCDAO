<template>
    <div class="boxtwo">
        <a name=Holds></a>
        <!-- <img src="../assets/bgimg2.svg" style="width: 100%;position: absolute; z-index: -1;"> -->
        <div>
            <p style="margin-left: 42.6%;margin-top: 8.8%;font-size: 50px;line-height: 50px;">$CCDAO</p>
            <p style="margin-left: 43.6%;margin-top: 16.6%;font-size: 40px;line-height: 50px;">{{$t("HOLDING")}}</p>
        </div>
        <div class="holdout">
            <div class="hold">
            <div class="holdbox">
                <img src="../assets/tag.svg" style="position: absolute;">
                <p style="margin-left: 160px;margin-top: 20px;font-size: 14px;line-height: 40px;">{{$t("ETH chain Positions")}}</p>
                <p style="margin-left: 160px;margin-top: 60px;font-size: 30px;">1000000CCDAO</p>
            </div>
            <div class="holdbox" style="margin-top:50px;">
                <img src="../assets/tag.svg" style="position: absolute;">
                <p style="margin-left: 160px;margin-top: 20px;font-size: 14px;line-height: 40px;"> {{$t("SWTC chain Positions")}}</p>
                <p style="margin-left: 160px;margin-top: 60px;font-size: 30px;">1000000CCDAO</p>
            </div>
            </div>
        <img src="../assets/bgimg2.svg" style="width: 100%;position: relative; z-index: -1;"> 
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
        width: 100%;
        position: relative;
        /* background-image: url("../assets/bgimg2.svg"); */
    }
    p{
        width: 183px;
        height: 50px;
        mix-blend-mode: normal;
        font-family: PingFangSC-Semibold, sans-serif;
        position: absolute;
        color: rgba(255, 255, 255, 1);
    }
    .holdout{
        display: flex;
        justify-content: center;
    }
    .hold{
        /* margin-left: 29.1%; */
        position: absolute;
        margin-top: 30%;
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