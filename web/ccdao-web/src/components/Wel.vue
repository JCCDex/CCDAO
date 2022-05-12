<template>
    <div class="boxone">
        <p class="wel" style="margin-left: 141px;margin-top: 134px;">{{$t("Welcome to")}}</p>
        <p class="tagCCDAO" style="margin-left: 141px;margin-top: 176px;">{{$t("CCDAO Community")}}</p>
        <p class="tagtext" style="margin-left: 141px;margin-top: 234px;">{{$t("A Community to improve Cross Chain experience")}}</p>
        <p class="tagCCDAO" style="margin-left: 141px;margin-top: 296px;">$CCDAO</p>
        <p class="tagtext" style="margin-left: 141px;margin-top: 362px;">{{$t("Created by Community, for the Community.")}}</p>
        <button class="numandvalue">
            <p style="left:20px;top:0px">{{$t("Total Volume Traded ")}}</p>
            <p style="left:237px;top:0px">{{$t("Fully Diluted Valuation")}}</p>
            <h1 style="left:20px;top:30px">{{num.toLocaleString()}}</h1>
            <h1 style="left:245px;top:30px">{{value.toLocaleString()}}</h1>
        </button>
        <img src="../assets/bgimg1.svg" style="width: 100%;position: relative; z-index: -1;display: flex;">
    </div>
</template>

<script>
export default {
    name:"Wel",
    data() {
        return {
            num:3628500320,
            value:5000680206
        }
    }
}
</script>

<style>
    .boxone{
        width: 100%;
        position: relative;
        /* background-image: url(../assets/bgimg1.svg);
        background-size: 100% 100%; */
    }
    .wel{
        width: 222px;
        height: 30px;
        position: absolute;
        mix-blend-mode: normal;
        color: rgba(68, 68, 68, 1);
        font-size: 40px;
        line-height: 30px;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .tagCCDAO{
        width: 501px;
        height: 50px;
        mix-blend-mode: normal;
        color: rgba(51, 147, 230, 1);
        font-size: 50px;
        line-height: 50px;
        position: absolute;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .tagtext{
        position: absolute;
        width: 470px;
        height: 22px;
        mix-blend-mode: normal;
        color: rgba(68, 68, 68, 1);
        font-size: 16px;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .numandvalue{
        margin-left: 140px;
        margin-top: 429px;
        width: 400px;
        height: 80px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
        border-radius: 16px;
        mix-blend-mode: normal;
        position: absolute;
        border: none;
    }
    .numandvalue p{
        width: 145px;
        height: 20px;
        mix-blend-mode: normal;
        color: rgba(161, 166, 169, 1);
        font-size: 14px;
        position: absolute;
    }
    .numandvalue h1{
        width: 137px;
        height: 28px;
        mix-blend-mode: normal;
        color: rgba(51, 147, 230, 1);
        font-size: 20px;
        position: absolute;
    }
</style>
