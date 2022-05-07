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
            <a href="#Holds">Holding</a>
            <a href="#ToBuy">How to Buy</a>
            <a href="#WebAdd">Countract Address</a>
        </div>
    </div>
    <a href="#Member" class="buttons" style="margin-left: 30px;margin-top: 12px;">Membership</a>
    <a href="" class="buttons" style="margin-left: 10px;margin-top: 12px;">Multi-Signers</a>
    <!-- <div class="downorder1" style="margin-left: 160px;margin-top: 12px;"> -->
    <div class="downorder1" style="margin-right: 2%;margin-top: 12px;">
        <button class="wallet" style="margin-left: 100px;margin-top: 0px;">
            <img src="../assets/Shape.svg">
            &nbsp;
            Connect Wallet
            &nbsp;
            <img src="../assets/triangular.svg">
        </button>
        <div class="walletbox">
            <p>Connect Wallet</p>

            <!-- <button class="WB" style="margin-left: 20px;">Connect MetaMask</button> -->
            <el-button @click="dialogVisible1=true,dlbtbool1=true,dlbtbool2=false"
             class="WB" style="margin-left: 20px;">Connect MetaMask</el-button>
            <!-- <button class="WB" style="margin-left: 20px;margin-top: 30px;">Import SWTC Wallet</button> -->
            <el-button @click="dialogVisible1=true,dlbtbool1=false,dlbtbool2=true"
             class="WB" style="margin-left: 20px;margin-top: 30px;">Import SWTC Wallet</el-button> 
        </div>
    </div>
    <!-- 对话框1 -->
         <el-dialog class="dlcss"
        :visible.sync="dialogVisible1"
        :show-close="false"
        >
          <div slot="title" class="dltitle">
              <p>导入SWTC钱包</p>
          </div>
          <div class="dlbox">
              <div class="dlbts">
                  <el-button class="dlbt" @click="dlbtbool1=true,dlbtbool2=false"
                   style="border-top-left-radius: 25px;border-bottom-left-radius: 25px;">SWTC钱包密钥</el-button>
                  <el-button class="dlbt" @click="dlbtbool2=true,dlbtbool1=false"
                   style="border-top-right-radius: 25px;border-bottom-right-radius: 25px;">SWTC文件</el-button>
                  <el-input v-show="dlbtbool1"
                    class="dlinput"
                    type="textarea"
                    :rows="2"
                    placeholder="请输入SWTC钱包密钥"
                    v-model="textarea">
                  </el-input>
                  <el-input v-show="dlbtbool2"
                    class="dlupload"
                    placeholder="点击导入SWTC文件"
                    type="file"
                    v-model="uploadfile">
                   </el-input>
              </div>
          </div>
          <span slot="footer">
            <el-button class="fobt" @click="dialogVisible1 = false">取 消</el-button>
            <el-button class="fobt" type="primary" @click="dialogVisible1 = false,dialogVisible2=true">确 定</el-button>
          </span>
        </el-dialog>

        <el-dialog class="dlcss"
        :visible.sync="dialogVisible2"
        :show-close="false"
        >
          <div slot="title" class="dltitle">
              <p>交易密码</p>
          </div>
          <div class="dlbox">
              <el-input placeholder="请输入密码" v-model="password"
               show-password=“true” clearable="true"></el-input>
          </div>
          <span slot="footer">
            <el-button class="fobt" @click="dialogVisible2 = false">取 消</el-button>
            <el-button class="fobt" type="primary" @click="dialogVisible2=false">确 定</el-button>
          </span>
        </el-dialog>

  </div>
</template>

<script>
export default {
    name:'Header',
    data() {
        return {
            dialogVisible1:false,
            dlbtbool1:false,
            textarea:"",
            dlbtbool2:false,
            uploadfile:"",
            dialogVisible2:false,
            password:""

        }
    }
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
        display: block;
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
    .WB{
        font-family: PingFangSC-Medium, sans-serif;
        border: none;
        width: 260px;
        height: 40px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        color: rgba(67, 162, 244, 1);
        border: 1px solid rgba(229, 232, 238, 1);
        border-radius: 18px;
        mix-blend-mode: normal;

    }
    .WB:hover{
        border: none;
        width: 260px;
        height: 40px;
        background: rgba(67, 162, 244, 1);
        background-blend-mode: normal;
        border-radius: 21.5px;
        mix-blend-mode: normal;
        color: rgba(255, 255, 255, 1);
        font-family: PingFangSC-Medium, sans-serif;
    }
    .dlcss{
        position: absolute;
        width: 360px;
        height: 320px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(237, 241, 246, 1);
        border-radius: 16px;
        mix-blend-mode: normal;
    }
    .dltitle{
        display: flex;
        justify-content: center;
        
        width: 360px;
        height: 50px;
        background: rgba(246, 249, 253, 1);
        background-blend-mode: normal;
        border-radius: 16px, 16px, 0px, 0px;
        mix-blend-mode: normal;
    }
    .dltitle p{
        width: 155px;
        height: 20px;
        mix-blend-mode: normal;
        color: rgba(52, 63, 93, 1);
        font-size: 16px;
        line-height: 20px;
    }
    .dlbox{
        width: 320px;
        height: 150px;

    }
    .dlbts{
        position: relative;
        width: 320px;
        height: 40px;
    }
    .dlbt{
        width: 160px;
        height: 40px;
        background-blend-mode: normal;
        mix-blend-mode: normal;
        font-family: PingFangSC-Medium, sans-serif;
        border: 1px solid rgba(216, 230, 254, 1);
        background: rgba(242, 246, 253, 1);
        color: rgba(120, 127, 147, 1);
    }
    .dlbt :hover{
        background: rgba(74.35800000000002, 147.0636, 206.55, 1);
        color: rgba(255, 255, 255, 1);
    } 
    .dlinput {
        width: 320px;
        height: 80px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(220, 230, 242, 1);
        border-radius: 12px;
        mix-blend-mode: normal;
    }
    .dlupload{
        width: 320px;
        height: 50px;
        background: rgba(209, 230, 248, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(220, 230, 242, 1);
        border-radius: 25px;
        mix-blend-mode: normal;
    }
    .fobt{
        width: 100px;
        height: 40px;
        background: rgba(255, 255, 255, 1);
        background-blend-mode: normal;
        border: 1px solid rgba(178, 187, 200, 1);
        border-radius: 25px;
        mix-blend-mode: normal;
        color: rgba(118, 133, 154, 1);
    }
    .fobt :hover{
        background: rgba(67.00000000000001, 162.00000000000003, 244, 1);
        color: rgba(255, 255, 255, 1);
    }
</style>