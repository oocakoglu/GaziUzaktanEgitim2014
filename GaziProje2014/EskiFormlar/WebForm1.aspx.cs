using System;
using System.Configuration;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Collections.Generic;
//using Telerik.QuickStart;
using Telerik.Web.UI;
using System.Linq;

namespace GaziProje2014.Forms
{
    public partial class WebForm1 : System.Web.UI.Page
    {
        protected void Page_Init(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                RadListView1.SelectedIndexes.Add(0);
                ConfigureMediaPlayer(GetVideoFiles()[0]);
            }
        }
        protected void RadListView1_NeedDataSource(object sender, RadListViewNeedDataSourceEventArgs e)
        {
            RadListView1.DataSource = GetVideoFiles();
        }
        protected void RadListView2_NeedDataSource(object sender, RadListViewNeedDataSourceEventArgs e)
        {
            RadListView2.DataSource = GetAudioFiles();
        }
        protected void RadListView1_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (RadListView2.SelectedItems.Count > 0)
            {
                ResetPlayListSelection(RadListView2);
            }
            ConfigureMediaPlayer(GetVideoFiles()[RadListView1.SelectedIndexes[0]]);
        }
        protected void RadListView2_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (RadListView1.SelectedItems.Count > 0)
            {
                ResetPlayListSelection(RadListView1);
            }
            ConfigureMediaPlayer(GetAudioFiles()[RadListView2.SelectedIndexes[0]]);
        }
        private void ResetPlayListSelection(RadListView listView)
        {
            listView.ClearSelectedItems();
            listView.Rebind();
        }
        private List<MediaPlayerAudioFile> GetAudioFiles()
        {
            var data = new List<MediaPlayerAudioFile>();
            string[] titles = new string[] { "Adamant Soul", "Freezing Wind", "Guitar Intro", "Daring Gaze" };
 
            for (int i = 0; i < titles.Length; i++)
            {
                var file = new MediaPlayerAudioFile() { Title = titles[i] };
                file.Sources.Add(new MediaPlayerSource() { Path = "audio/audio" + (i + 1) + ".mp3", MimeType = "audio/mpeg" });
                file.Sources.Add(new MediaPlayerSource() { Path = "audio/audio" + (i + 1) + ".ogg", MimeType = "audio/ogg" });
                data.Add(file);
            }
            return data;
        }
        private List<MediaPlayerVideoFile> GetVideoFiles()
        {
            var data = new List<MediaPlayerVideoFile>();
            string[] fileNames = new string[] { "AppBuilder", "justCode", "testStudio" };
            string[] titles = new string[] { "AppBuilder", "Improve VS with JustCode", "Testing with TestStudio" };
 
            for (int i = 0; i < fileNames.Length; i++)
            {
                var file = new MediaPlayerVideoFile() { Title = titles[i], Path = fileNames[i] };
                file.Sources.Add(new MediaPlayerSource() { Path = "video/" + fileNames[i] + ".mp4" });
                file.Sources.Add(new MediaPlayerSource() { Path = "video/" + fileNames[i] + ".webm" });
                file.Sources.Add(new MediaPlayerSource() { Path = "video/" + fileNames[i] + ".ogv" });
 
                data.Add(file);
            }
            return data;
        }
        protected void RadButton1_Click(object sender, EventArgs e)
        {
            if (RadListView1.SelectedItems.Count > 0)
            {
                ResetPlayListSelection(RadListView1);
            }
            else if (RadListView2.SelectedItems.Count > 0)
            {
                ResetPlayListSelection(RadListView2);
            }
            MediaPlayerFile file = new MediaPlayerVideoFile() { Title = "YouTube" };
            file.Sources.Add(new MediaPlayerSource() { Path = RadTextBox1.Text });
            ConfigureMediaPlayer(file);
        }
        private void ConfigureMediaPlayer(MediaPlayerFile file)
        {
            RadMediaPlayer1.Sources.Clear();
            RadMediaPlayer1.StartTime = 0;
            RadMediaPlayer1.Muted = false;
            RadMediaPlayer1.AutoPlay = false;
            RadMediaPlayer1.Title = file.Title;
            RadMediaPlayer1.Poster = file.Title == "AppBuilder" ? "Image/appBuilderPoster.png" : "";
 
            foreach (MediaPlayerSource source in file.Sources)
            {
                RadMediaPlayer1.Sources.Add(source);
                source.Path = source.Path;
                source.MimeType = source.MimeType;
 
                MediaPlayerSource hdSource = new MediaPlayerSource();
                RadMediaPlayer1.Sources.Add(hdSource);
                hdSource.MimeType = source.MimeType;
                hdSource.Path = source.Path;
                hdSource.IsHD = true;
            }
        }
    }
}