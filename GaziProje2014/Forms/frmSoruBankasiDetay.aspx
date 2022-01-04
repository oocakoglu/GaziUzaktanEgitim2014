<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="frmSoruBankasiDetay.aspx.cs" Inherits="GaziProje2014.Forms.frmSoruBankasiDetay" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <style>
        .SolSorular{
            position: absolute;
            top: 40px;
            left: 0px;      
            bottom: 40px;   
            width:500px;

            overflow: scroll;
            overflow-x:hidden; 
            background-color:white;   
            opacity: 0.9; 
            filter: alpha(opacity=90); 
        }

        .SagSorular{
            position: absolute;
            top: 40px;
            left: 500px;      
            bottom: 40px;   
            right:0px;
            padding:10px;

            overflow: scroll;
            overflow-x:hidden; 
            background-color:white;   
            opacity: 0.9; 
            filter: alpha(opacity=90);
        }


    </style>


    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td colspan="4">
                    <telerik:RadComboBox ID="rdDersler" runat="server" Width="500px" OnSelectedIndexChanged="rdDersler_SelectedIndexChanged" AutoPostBack="true">
                    </telerik:RadComboBox>
                </td>
                <td class="tdCellBaslik"></td>                                                                                       
            </tr>
        </table>
    </div>
    <div class="contentUst40Golge">
    </div>
     
    
    
<asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
            <ContentTemplate>



            <div class="SolSorular">
                <telerik:RadGrid ID="grdSorular" runat="server" OnSelectedIndexChanged="grdSorular_SelectedIndexChanged">
                    <ClientSettings EnableRowHoverStyle="true" EnablePostBackOnRowClick="true">
                        <Selecting AllowRowSelect="true"></Selecting>
                    </ClientSettings>

                    <MasterTableView AutoGenerateColumns="False" DataKeyNames="SoruId">
                        <Columns>
                            <telerik:GridBoundColumn DataField="SoruId" DataType="System.Int32" FilterControlAltText="Filter SoruId column" HeaderText="SoruId" ReadOnly="True" SortExpression="SoruId" UniqueName="SoruId" Visible="false">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                            </telerik:GridBoundColumn>

                            <telerik:GridBoundColumn DataField="SoruKonu"  HeaderText="SoruKonu"  UniqueName="SoruKonu">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                            </telerik:GridBoundColumn>

                            <telerik:GridBoundColumn DataField="SoruIcerik" HeaderText="SoruIcerik" UniqueName="SoruIcerik">
                                <ColumnValidationSettings>
                                    <ModelErrorMessage Text="" />
                                </ColumnValidationSettings>
                            </telerik:GridBoundColumn>

                        </Columns>
                    </MasterTableView>

                </telerik:RadGrid>

            </div>
               
           <div class="SagSorular"  id="dvSag">
         
         <telerik:RadTabStrip ID="rtbstMain" runat="server" MultiPageID="soruMultiPage" SelectedIndex="0" Visible="true">
               <Tabs>

                   <telerik:RadTab runat="server" Text="Görüntüle" Selected="True" PageViewID="rdpageGoruntule">
                   </telerik:RadTab>

                   <telerik:RadTab runat="server" Text="Düzenle"  PageViewID="rdpageDuzenle">
                   </telerik:RadTab>

               </Tabs>
           </telerik:RadTabStrip>

            <telerik:RadMultiPage ID="soruMultiPage" runat="server" SelectedIndex="0">
                <telerik:RadPageView ID="rdpageGoruntule" runat="server">
                   
                    <fieldset class="fieldsetForm">                        
                        <legend class="legendForm">&nbsp;Soru&nbsp;</legend>
                        <asp:Image ID="imgSoruResim" runat="server"/><br />                                                    
                        <asp:Label ID="lblSoruIcerik" runat="server" Text="Şekilde meyve hangi geometik şekle sahiptir" />                      
                        <asp:RadioButtonList ID="rdCevaplar" runat="server" Enabled="false">
                        </asp:RadioButtonList>
                    </fieldset>  
                            
                </telerik:RadPageView>
                <telerik:RadPageView ID="rdpageDuzenle" runat="server">
                        <asp:Label ID="lblBilgi" runat="server" Text=""></asp:Label>

                        <fieldset class="fieldsetForm1">
                              <legend class="legendForm1">Soru Giriniz</legend>
                                    
                                <table style="width:100%;">
                                    <tr>
                                        <td style="width:110px;">
                                            <asp:HiddenField ID="hdnSoruId" runat="server" />
                                        </td>
                                        <td style="width:180px;">
                                            <asp:HiddenField ID="hdnResimYol" runat="server" />
                                        </td>  
                                        <td style="width:110px;"></td>                  
                                        <td style="width:180px;"></td>                    
                                    </tr>
                                    <tr>
                                        <td>Soru Konu</td>
                                        <td>
                                            <asp:TextBox ID="txtSoruKonu" runat="server"  Width="300px"></asp:TextBox>                        
                                        </td>
                                        <td colspan="2">
                        
                                        </td>
                
                                    </tr>
                                    <tr>
                                        <td>Soru Resim</td>
                                        <td>
                                            <asp:FileUpload ID="fileUploadImage" runat="server" Width="182px" />                                   
                                        </td>
                                        <td>
                                            <telerik:RadButton ID="btnUpload" runat="server" Text="Resmi Yükle" OnClick="btnUpload_Click"></telerik:RadButton>
                           
                                        </td>
                                        <td>
                                            <telerik:RadButton ID="btnResimSil" runat="server" Text="Resmi Sil" OnClick="btnResimSil_Click"></telerik:RadButton>                             
                                        </td>
                                    </tr>
                                    <tr>
                                        <td></td>
                                        <td colspan="3">
                                            <asp:Image ID="imgSoruResmiDuzenle" runat="server"  />
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4">Soru:
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4">
                                            <telerik:RadTextBox ID="txtSoruIcerik" runat="server" Height="69px" TextMode="MultiLine" Width="100%"></telerik:RadTextBox>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="4">


                                            <table style="width: 100%">
                                                <tr>
                                                    <td style="width:74px;">
                                                        <asp:RadioButton ID="rdCvp1" runat="server"  Text="Cevap 1:" GroupName="groupDogruCevap" Font-Size="X-Large" />
                                                    </td>
                                                    <td>
                                                        <telerik:RadTextBox ID="txtCvp1" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                                    </td>
                                                </tr>

                                                <tr>
                                                    <td>
                                                        <asp:RadioButton ID="rdCvp2" runat="server"  Text="Cevap 2:" GroupName="groupDogruCevap" Font-Size="X-Large" />
                                                    </td>
                                                    <td>
                                                        <telerik:RadTextBox ID="txtCvp2" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                                    </td>
                                                </tr>

                                                <tr>
                                                    <td>
                                                        <asp:RadioButton ID="rdCvp3" runat="server"  Text="Cevap 3:" GroupName="groupDogruCevap" Font-Size="Large" />
                                                    </td>
                                                    <td>
                                                        <telerik:RadTextBox ID="txtCvp3" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                                    </td>
                                                </tr>

                                                <tr>
                                                    <td>
                                                        <asp:RadioButton ID="rdCvp4" runat="server"  Text="Cevap 4:" GroupName="groupDogruCevap" Font-Size="Large" />
                                                    </td>
                                                    <td>
                                                        <telerik:RadTextBox ID="txtCvp4" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                                    </td>
                                                </tr>

                                                <tr>
                                                    <td>
                                                        <asp:RadioButton ID="rdCvp5" runat="server"  Text="Cevap 5:" GroupName="groupDogruCevap" Font-Size="Large" />
                                                    </td>
                                                    <td>
                                                        <telerik:RadTextBox ID="txtCvp5" runat="server" Height="33px" TextMode="MultiLine" Width="100%" Text=""></telerik:RadTextBox>
                                                    </td>
                                                </tr>
                                            </table>

                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <asp:Button ID="btnGuncelle" runat="server" Text="Güncelle" Width="70px" OnClick="btnGuncelle_Click"></asp:Button>
                                        </td>
                                        <td>
                                        </td>
                                        <td></td>
                                        <td></td>
                                    </tr>
                                </table>

                        </fieldset>

                </telerik:RadPageView>
            </telerik:RadMultiPage>

          </div> 
      

            <div class="contentAlt30">
                <telerik:RadButton Width="70px" ID="RadButton3" runat="server" Text="Geri">
                     <Icon PrimaryIconUrl="~/Style/btnBack.png"/>
                </telerik:RadButton> 

                <telerik:RadButton Width="100px" ID="btnYeniSoru" runat="server" Text="Yeni Soru Ekle" OnClick="btnYeniSoru_Click"> 
                </telerik:RadButton> 

                <telerik:RadButton Width="100px" ID="btnSoruSil" runat="server" Text="Soruyu Sil" OnClick="btnSoruSil_Click"> 
                </telerik:RadButton> 

                

            </div>
            <div class="contentAlt30Golge"> 
            </div> 
             <asp:HiddenField ID="hdnOgretmenDersId" runat="server" />

            </ContentTemplate>
            <Triggers>
                <asp:PostBackTrigger ControlID="btnUpload"  />
            </Triggers>

           
 </asp:UpdatePanel>

</asp:Content>
