<template>
  <div class="box">
    <img class="boximg" src="../assets/CCDAO.svg">
    <div class="downorder" style="margin-left: 17.5%;margin-top: 12px;">
        <button class="ComunityCss">
            Comunity &nbsp;<img src="../assets/downchart.svg">
        </button>
        <div class="ordertext">
            <a href="">Twitter</a>
            <a href="">Discord</a>
            <a href="">Telegram</a>
        </div>
    </div>
    <div class="downorder" style="margin-left: 30px;margin-top: 12px;">
        <button class="ComunityCss">
            $CCDAO &nbsp;<img src="../assets/downchart.svg">
        </button>
        <div class="ordertext">
            <a href="">Holding</a>
            <a href="">How to Buy</a>
            <a href="">Countract Address</a>
        </div>
    </div>
    <a href="" class="buttons" style="margin-left: 30px;margin-top: 12px;">Membership</a>
    <a href="" class="buttons" style="margin-left: 10px;margin-top: 12px;">Multi-Signers</a>
    <!-- <div class="downorder1" style="margin-left: 160px;margin-top: 12px;"> -->
    <div class="downorder1" style="margin-right: 2%;margin-top: 12px;">
        <button class="wallet" style="margin-left: 100px;margin-top: 0px;">
            <img src="../assets/Shape.svg">
            &nbsp;
            Connect Wallet
            &nbsp;
            <img src="../assets/三角形.svg">
        </button>
        <div class="walletbox">
            <p>Connect Wallet</p>
            <button class="CM">Connect MetaMask</button>
            <button class="ISW">Import SWTC Wallet</button>
        </div>
    </div>
  </div>
</template>

<script>
export default {
    name:'Header'
}
</script>

<style>
    .box{
        top: 0px;
        left: 0px;
        z-index: 1;
        width: 100%;
        height: 60px;
        background: rgba(246, 249, 253, 1);
        background-blend-mode: normal;
        box-shadow: 0px 1px 5px rgba(201, 223, 240, 1);
        mix-blend-mode: normal;
        position: fixed;
    }
    .boximg{
        margin-left: 47px;
        margin-top: 10px;
        width: 139px;
        height: 40px;
        float: left;
    }
    .downorder{
        width: 100px;
        height: auto;
        position:  relative;
        float: left;
    }
    .downorder:hover .ComunityCss{
        background-color: rgba(230, 236, 243, 1);
    }
    .downorder:hover .ordertext{
        display: block;
    }
    .downorder:hover a{
        display: block;
    }
    .ComunityCss{
        width: 120px;
        height: 36px;
        background-color: rgba(246, 249, 253, 1);
        background-blend-mode: normal;
        border-radius: 3px;
        mix-blend-mode: normal;
        text-align: center;
        border: none;
        float: left;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .ordertext{
        width: 120px;
        height: 140px;
        margin-top: 12px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(251, 252, 254, 1);
        box-shadow: 0px 2px 4px rgba(228, 237, 246, 0.5);
        border-radius: 3px;
        float: left;
        text-align: center;
        font-size: 14px;
        font-family: PingFangSC-Medium, sans-serif;
        display: none;
    }
    .ordertext a{
        width: 120px;
        height: 40px;
        vertical-align:middle;
        line-height:40px;
        border-radius: 3px;
        mix-blend-mode: normal;
        text-decoration: none;
        color: rgba(108, 116, 124, 1);
        display: none;
    }
    .ordertext a:hover{
        background: rgba(244, 246, 248, 1);
        background-blend-mode: normal;
        color: rgba(12, 40, 69, 1);

    }
    .buttons{
        width: 120px;
        height: 36px;
        color: rgba(12, 40, 69, 1);
        background-blend-mode: normal;
        border-radius: 3px;
        mix-blend-mode: normal;
        text-align: center;
        text-decoration: none;
        float: left;
        /* 文字上下居中 */
        vertical-align:middle;
        line-height:36px;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .buttons:hover{
         background-color: rgba(230, 236, 243, 1);
    }

    .downorder1{
        width: 300px;
        height: auto;
        position:  relative;
        float: right;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .downorder1:hover .walletbox{
        display: block;
    }
    .wallet{
        border: none;
        width: 180px;
        height: 36px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        box-shadow: 0px 0px 4px 2px rgba(237, 240, 242, 1);
        border-radius: 18px;
        mix-blend-mode: normal;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .walletbox{
        margin-top: 12px;
        width: 300px;
        height: 220px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(216, 221, 230, 1);
        box-shadow: 2px 2px 6px rgba(225, 229, 234, 1);
        border-radius: 16px;
        mix-blend-mode: normal;
        display: none;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .downorder1 p{
        position: relative;
        margin-left: auto;
        margin-right: auto;
        margin-top: 24px;
        text-align: center;
        width: 172px;
        height: 20px;
        mix-blend-mode: normal;
        color: rgba(12, 40, 69, 1);
        font-size: 16px;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .CM{
        border: none;
        margin-left: 20px;
        width: 260px;
        height: 40px;
        background: rgba(67, 162, 244, 1);
        background-blend-mode: normal;
        border-radius: 21.5px;
        mix-blend-mode: normal;
        font-family: PingFangSC-Medium, sans-serif;
    }
    .ISW{
        font-family: PingFangSC-Medium, sans-serif;
        margin-left: 20px;
        margin-top: 30px;
        border: none;
        width: 262px;
        height: 36px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(229, 232, 238, 1);
        border-radius: 18px;
        mix-blend-mode: normal;

    }
</style>