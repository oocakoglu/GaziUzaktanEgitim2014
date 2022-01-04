using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Telerik.Web.UI;

namespace GaziProje2014.Pages
{
    public partial class KullaniciListesi : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void RadButton1_Click1(object sender, EventArgs e)
        {
            string SqlText = @"Select K.KullaniciId, K.KullaniciAdi, K.KullaniciSifre, K.Adi, K.Soyadi,
                                        KT.KullaniciTipAdi, K.DogumTarihi, K.Cinsiyet, K.CepTel, K.EvTel, 
                                        K.Email, K.IlKodu, K.IlceKodu, K.Adres, K.Resim, K.KayitTarihi, 
                                        K.Onay, I1.IlAdi, I2.IlceAdi From Kullanicilar K
                                        Left Join Ilce I2 ON K.IlceKodu = I2.IlceKodu
                                        Left Join Il I1 ON K.IlKodu = I1.IlKodu
                                        Left Join KullaniciTipleri KT ON KT.KullaniciTipId = K.KullaniciTipi
                                        Where 1 = 1 ";


            if (txtKullaniciTipi.Text != "")
            {
                SqlText = SqlText + " And KT.KullaniciTipAdi like '" + txtKullaniciTipi.Text + "%'";
            }

            if (txtAdi.Text != "")
            {
                SqlText = SqlText + " And K.Adi like '" + txtAdi.Text + "%'";
            }
            if (txtSoyadi.Text != "")
            {
                SqlText = SqlText + " And K.Soyadi like '" + txtSoyadi.Text + "%'";
            }

            SqlDataSource1.SelectCommand = SqlText + "ORDER BY K.KullaniciId";
        }



        protected void RadAjaxManager1_AjaxRequest(object sender, AjaxRequestEventArgs e)
        {

            if (e.Argument == "Rebind")
            {
                SqlDataSource1.DataBind();
                RadGrid1.MasterTableView.SortExpressions.Clear();
                RadGrid1.MasterTableView.GroupByExpressions.Clear();
                RadGrid1.Rebind();
            }
            else if (e.Argument == "RebindAndNavigate")
            {
                RadGrid1.MasterTableView.SortExpressions.Clear();
                RadGrid1.MasterTableView.GroupByExpressions.Clear();
                RadGrid1.MasterTableView.CurrentPageIndex = RadGrid1.MasterTableView.PageCount - 1;
                RadGrid1.Rebind();
            }


        }
    }
}