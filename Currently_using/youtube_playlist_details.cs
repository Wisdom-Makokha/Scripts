using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using CsvHelper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace YouTubePlaylistExporter
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("YouTube Playlist Metadata Exporter");
            Console.WriteLine("----------------------------------");

            if (args.Length == 0)
            {
                Console.WriteLine("Please provide a YouTube playlist URL as an argument.");
                Console.WriteLine("Example: YouTubePlaylistExporter \"https://www.youtube.com/playlist?list=PLAYLIST_ID\"");
                return;
            }

            string playlistUrl = args[0];
            string outputFile = args.Length > 1 ? args[1] : "playlist_videos.csv";

            try
            {
                // Check if yt-dlp exists
                if (!IsToolAvailable("yt-dlp"))
                {
                    Console.WriteLine("Error: yt-dlp is not installed or not in PATH.");
                    Console.WriteLine("Please install it from https://github.com/yt-dlp/yt-dlp");
                    return;
                }

                Console.WriteLine($"Fetching metadata for playlist: {playlistUrl}");

                // Get JSON data from yt-dlp
                List<VideoInfo> videos = GetPlaylistMetadata(playlistUrl);

                if (videos.Count == 0)
                {
                    Console.WriteLine("No videos found in the playlist or the playlist is private.");
                    return;
                }

                Console.WriteLine($"Found {videos.Count} videos in the playlist.");

                // Export to CSV
                ExportToCsv(videos, outputFile);

                Console.WriteLine($"Playlist data successfully exported to: {Path.GetFullPath(outputFile)}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred: {ex.Message}");
            }
        }

        static bool IsToolAvailable(string toolName)
        {
            try
            {
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = toolName,
                        Arguments = "--version",
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };

                process.Start();
                process.WaitForExit(2000);
                return process.ExitCode == 0;
            }
            catch
            {
                return false;
            }
        }

        static List<VideoInfo> GetPlaylistMetadata(string playlistUrl)
        {
            var videos = new List<VideoInfo>();

            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "yt-dlp",
                    Arguments = $"--dump-json --flat-playlist \"{playlistUrl}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    StandardOutputEncoding = System.Text.Encoding.UTF8
                }
            };

            process.Start();

            // Read output line by line (each line is a separate JSON object)
            while (!process.StandardOutput.EndOfStream)
            {
                string line = process.StandardOutput.ReadLine();
                if (!string.IsNullOrWhiteSpace(line))
                {
                    try
                    {
                        var videoJson = JObject.Parse(line);
                        var video = new VideoInfo
                        {
                            Id = videoJson["id"]?.ToString(),
                            Title = videoJson["title"]?.ToString(),
                            Duration = videoJson["duration"]?.ToObject<double?>(),
                            Uploader = videoJson["uploader"]?.ToString(),
                            UploaderUrl = videoJson["uploader_url"]?.ToString(),
                            ViewCount = videoJson["view_count"]?.ToObject<long?>(),
                            UploadDate = ParseUploadDate(videoJson["upload_date"]?.ToString()),
                            Description = videoJson["description"]?.ToString(),
                            ThumbnailUrl = videoJson["thumbnail"]?.ToString(),
                            PlaylistIndex = videoJson["playlist_index"]?.ToObject<int?>()
                        };

                        videos.Add(video);
                    }
                    catch (JsonException ex)
                    {
                        Console.WriteLine($"Error parsing JSON: {ex.Message}");
                    }
                }
            }

            process.WaitForExit();

            if (process.ExitCode != 0)
            {
                string error = process.StandardError.ReadToEnd();
                throw new Exception($"yt-dlp error: {error}");
            }

            return videos;
        }

        static DateTime? ParseUploadDate(string uploadDate)
        {
            if (string.IsNullOrWhiteSpace(uploadDate) || uploadDate.Length != 8)
                return null;

            if (DateTime.TryParseExact(uploadDate, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var result))
                return result;

            return null;
        }

        static void ExportToCsv(List<VideoInfo> videos, string outputPath)
        {
            using (var writer = new StreamWriter(outputPath))
            using (var csv = new CsvWriter(writer, CultureInfo.InvariantCulture))
            {
                csv.WriteRecords(videos);
            }
        }
    }

    public class VideoInfo
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string URL => $"https://www.youtube.com/watch?v={Id}";
        public double? Duration { get; set; }
        public string DurationFormatted => Duration.HasValue ? 
            TimeSpan.FromSeconds(Duration.Value).ToString() : "N/A";
        public string Uploader { get; set; }
        public string UploaderUrl { get; set; }
        public long? ViewCount { get; set; }
        public DateTime? UploadDate { get; set; }
        public string UploadDateFormatted => UploadDate?.ToString("yyyy-MM-dd") ?? "N/A";
        public string Description { get; set; }
        public string ThumbnailUrl { get; set; }
        public int? PlaylistIndex { get; set; }
    }
}