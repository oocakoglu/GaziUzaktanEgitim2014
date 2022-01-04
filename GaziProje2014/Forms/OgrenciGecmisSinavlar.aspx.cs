using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;

namespace GaziProje2014.Forms
{
    public partial class OgrenciGecmisSinavlar : System.Web.UI.Page
    {

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                grdSinavlarBind();
            }
        }

        protected void btnSorgula_Click(object sender, EventArgs e)
        {
            grdSinavlarBind();
        }

        private void grdSinavlarBind()
        {
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            GAZIEntities gaziEntities = new GAZIEntities();

            string sqlstr = "Select "
                           + "S.SinavId, S.SinavAdi, OS.OgrenciSinavId, "
                           + "Case "
                           + "When OS.OgrenciSinavId IS NULL THEN 'Girilmedi' "
                           + "ELSE 'Girildi'  end  as Durum, "
                           + "Case "
                           + "When D.DersAdi IS NULL THEN 'Genel Sınav' "
                           + "ELSE D.DersAdi  end DersAdi, "
                           + "OS.BitisZamani, S.BitisTarihi,  "
                           + "Count(*) as SoruSayisi, "
                           + "sum(case when OSD.OgrenciCvp = So.DogruCvp THEN 1 ELSE 0 END) as DogruCevap, "
                           + "sum(case when OSD.OgrenciCvp <> So.DogruCvp and OSD.OgrenciCvp > 0 THEN 1 ELSE 0 END) as YanlisCevap, "
                           + "sum(case when OSD.OgrenciCvp = 0 THEN 1 ELSE 0 END) as BosCevap "
                           + "From Sinav S "
                           + "LEFT JOIN OgrenciSinav OS ON S.SinavId = OS.SinavId And OS.OgrenciId = " + kullaniciId + " "
                           + "LEFT JOIN OgretmenDersler OD ON OD.OgretmenDersId = S.OgretmenDersId "
                           + "LEFT JOIN Dersler D ON D.DersId = OD.DersId "
                           + "LEFT JOIN OgrenciSinavDetay OSD ON OSD.OgrenciSinavId = OS.OgrenciSinavId "
                           + "LEFT JOIN Sorular So ON OSD.SoruId = So.SoruId "
                           + "WHERE (OS.BitisZamani < GETDATE() OR S.BitisTarihi < GETDATE()) ";

            if (txtDersAdi.Text != "")
                sqlstr = sqlstr + " And D.DersAdi like '" + txtDersAdi.Text + "%' ";

            if (txtSinavAdi.Text != "")
                sqlstr = sqlstr + " And S.SinavAdi like '" + txtSinavAdi.Text + "%' ";

            sqlstr = sqlstr + "group by  "
                            + "S.SinavId, S.SinavAdi, OS.OgrenciSinavId, "
                            + "D.DersAdi, "
                            + "OS.BitisZamani, S.BitisTarihi ORDER BY BitisTarihi DESC";


            List<GirilenSinavlar> girilenSinavlar = gaziEntities.Database.SqlQuery<GirilenSinavlar>(sqlstr).ToList();

            grdSinavlar.DataSource = girilenSinavlar;
            grdSinavlar.DataBind();
        }

        private class GirilenSinavlar
        {
            public int SinavId { get; set; }          

            public string SinavAdi { get; set; }
            public int? OgrenciSinavId { get; set;}
            public string Durum { get; set; }    
            public string DersAdi { get; set; }
            public DateTime? BitisZamani { get; set; }
            public DateTime? BitisTarihi { get; set; }
            public int? SoruSayisi { get; set;}
            public int? DogruCevap { get; set;}
            public int? YanlisCevap { get; set;}
            public int? BosCevap { get; set;}
        } 

    }
}