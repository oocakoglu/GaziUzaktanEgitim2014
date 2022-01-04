using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class SoruBankasi : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdSoruBankasiBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdSoruBankasiBind();
        }

        protected void btnDersSorulari_Click(object sender, EventArgs e)
        {
            if (grdSoruBankasi.SelectedItems.Count > 0)
            {
                string ogretmenDersId = grdSoruBankasi.SelectedValues["OgretmenDersId"].ToString();
                Session.Add("OgretmenDersId", ogretmenDersId);
                Response.Redirect("~/Forms/frmSoruBankasiDetay.aspx");
            }
        }

        protected void btnYeniSoru_Click(object sender, EventArgs e)
        {
            if (grdSoruBankasi.SelectedItems.Count > 0)
            {
                string ogretmenDersId = grdSoruBankasi.SelectedValues["OgretmenDersId"].ToString();
                Session.Add("SoruOgretmenDersId", ogretmenDersId);
                Response.Redirect("~/Forms/SoruDetay.aspx");
            }
        }

        private void grdSoruBankasiBind()
        {
           GAZIEntities gaziEntities = new GAZIEntities();

           string sqlStr = "SELECT od.OgretmenDersId, d.DersAdi, k.Adi + ' ' + k.Soyadi as Ogretmen, "
                        + "COUNT(si.SinavId) as SinavSayisi, "
                        + "count(s.SoruId) as SoruSayisi,  "
                        + "count(sd.SinavDetayId) as SinavdaKullanilanSoru "
                        + "FROM OgretmenDersler od "
                        + "INNER JOIN Dersler d ON od.DersId = d.DersId "
                        + "INNER JOIN Kullanicilar k ON od.OgretmenId = k.KullaniciId "
                        + "LEFT  JOIN Sinav si ON si.OgretmenDersId = od.OgretmenDersId  "
                        + "LEFT  JOIN Sorular s ON od.OgretmenDersId = s.OgretmenDersId "
                        + "LEFT  JOIN SinavDetay sd ON s.SoruId = sd.SoruId "
                        + "WHERE od.UstOnay = 1 ";
            
            int kullaniciTipiId = Convert.ToInt32(Session["KullaniciTipiId"].ToString());
            if (kullaniciTipiId != 1)
            {
                int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
                sqlStr = sqlStr + " AND od.OgretmenId = " + kullaniciId.ToString() + " ";
            }

            if (txtDersAdi.Text != "")
                sqlStr = sqlStr + " AND d.DersAdi like '" + txtDersAdi.Text + "%' ";

            sqlStr = sqlStr
                    + "GROUP BY "
                    + "od.OgretmenDersId, d.DersAdi, k.Adi + ' ' + k.Soyadi ";

            List<SoruOzetDetail> soruOzetList = gaziEntities.Database.SqlQuery<SoruOzetDetail>(sqlStr).ToList();
            grdSoruBankasi.DataSource = soruOzetList;
            grdSoruBankasi.DataBind();

        }
        
        private class SoruOzetDetail
        {
            public int OgretmenDersId { get; set; }
            public string DersAdi { get; set; }
            public string Ogretmen { get; set; }
            public int? SinavSayisi { get; set; }
            public int? SoruSayisi { get; set; }
            public int? SinavdaKullanilanSoru { get; set; }
        }  
    }
}