import 'package:chewie/chewie.dart';
import 'package:fish_redux/fish_redux.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:movie/actions/Adapt.dart';
import 'package:movie/actions/base_api.dart';
import 'package:movie/customwidgets/custom_video_controls.dart';
import 'package:movie/models/base_api_model/base_user.dart';
import 'package:movie/models/base_api_model/tvshow_comment.dart';
import 'package:movie/models/base_api_model/tvshow_stream_link.dart';
import 'package:movie/models/episodemodel.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'action.dart';
import 'state.dart';

Effect<TvShowLiveStreamPageState> buildEffect() {
  return combineEffects(<Object, Effect<TvShowLiveStreamPageState>>{
    TvShowLiveStreamPageAction.action: _onAction,
    TvShowLiveStreamPageAction.episodeCellTapped: _episodeCellTapped,
    TvShowLiveStreamPageAction.addComment: _addComment,
    Lifecycle.initState: _onInit,
    Lifecycle.dispose: _onDispose,
  });
}

void _onAction(Action action, Context<TvShowLiveStreamPageState> ctx) {}

void _onInit(Action action, Context<TvShowLiveStreamPageState> ctx) async {
  final Object ticker = ctx.stfState;
  ctx.state.episodelistController = ScrollController();
  ctx.state.commentController = TextEditingController();
  ctx.state.tabController = TabController(vsync: ticker, length: 2)
    ..addListener(() {
      if (ctx.state.tabController.index == 1)
        ctx.dispatch(TvShowLiveStreamPageActionCreator.onShowBottom(true));
      else
        ctx.dispatch(TvShowLiveStreamPageActionCreator.onShowBottom(false));
    });
  final _streamLinks = await BaseApi.getTvSeasonStreamLinks(
      ctx.state.tvid, ctx.state.season.season_number);
  if (_streamLinks != null) {
    initVideoPlayer(ctx, _streamLinks);
    ctx.dispatch(
        TvShowLiveStreamPageActionCreator.setStreamLinks(_streamLinks));
    ctx.dispatch(TvShowLiveStreamPageActionCreator.episodeCellTapped(
        _streamLinks.list
            .singleWhere((d) => d.episode == ctx.state.episodeNumber)));
  }
}

void _onDispose(Action action, Context<TvShowLiveStreamPageState> ctx) {
  ctx.state.episodelistController.dispose();
  ctx.state.tabController.dispose();
  ctx.state.commentController.dispose();
  ctx.state.chewieController?.dispose();
  ctx.state.youtubePlayerController?.dispose();
  ctx.state.videoControllers.forEach((f) => f.dispose());
}

void _addComment(Action action, Context<TvShowLiveStreamPageState> ctx) async {
  final String _commentTxt = action.payload;
  if (_commentTxt.isNotEmpty && ctx.state.user != null) {
    final String _date = DateTime.now().toString();
    final TvShowComment _comment = TvShowComment.fromParams(
        mediaId: ctx.state.tvid,
        comment: _commentTxt,
        uid: ctx.state.user.uid,
        updateTime: _date,
        createTime: _date,
        season: ctx.state.season.season_number,
        episode: ctx.state.episodeNumber,
        u: BaseUser.fromParams(
            uid: ctx.state.user.uid,
            userName: ctx.state.user.displayName,
            photoUrl: ctx.state.user.photoUrl),
        like: 0);
    ctx.state.commentController.clear();
    ctx.dispatch(TvShowLiveStreamPageActionCreator.insertComment(_comment));
    BaseApi.createTvShowComment(_comment).then((r) {
      if (r != null) _comment.id = r.id;
      print(ctx.state.comments.data);
    });
  }
}

void _episodeCellTapped(
    Action action, Context<TvShowLiveStreamPageState> ctx) async {
  final TvShowStreamLink e = action.payload;
  if (e != null) {
    videoSourceChange(ctx, e);
    final Episode episode = ctx.state.season.episodes
        .singleWhere((d) => d.episode_number == e.episode);
    ctx.dispatch(TvShowLiveStreamPageActionCreator.episodeChanged(episode));
    await ctx.state.episodelistController.animateTo(
        Adapt.px(330) * (e.episode - 1),
        curve: Curves.ease,
        duration: Duration(milliseconds: 300));
    final comment = await BaseApi.getTvShowComments(
        ctx.state.tvid, ctx.state.season.season_number, e.episode);
    if (comment != null)
      ctx.dispatch(TvShowLiveStreamPageActionCreator.setComments(comment));
  }
}

void initVideoPlayer(
    Context<TvShowLiveStreamPageState> ctx, TvShowStreamLinks streamLinks) {
  final _list = streamLinks.list;
  if (_list.length > 0) {
    ctx.state.videoControllers =
        _list.map((f) => VideoPlayerController.network(f.streamLink)).toList();
  }
}

void videoSourceChange(
    Context<TvShowLiveStreamPageState> ctx, TvShowStreamLink d) {
  int index = ctx.state.streamLinks.list.indexOf(d);
  if (ctx.state.chewieController != null) {
    ctx.state.chewieController.dispose();
    ctx.state.chewieController.videoPlayerController
        .seekTo(Duration(seconds: 0));
    ctx.state.chewieController.videoPlayerController.pause();
  }

  ctx.state.streamLinkType = d.streamLinkType;
  if (d.streamLinkType.name == 'WebView') {
    ctx.state.streamAddress = d.streamLink;
    ctx.state.chewieController = null;
  } else if (d.streamLinkType.name == 'YouTube') {
    ctx.state.streamAddress = YoutubePlayer.convertUrlToId(d.streamLink);
    ctx.state.chewieController = null;
    if (ctx.state.youtubePlayerController == null)
      ctx.state.youtubePlayerController = new YoutubePlayerController(
        initialVideoId: ctx.state.streamAddress,
        flags: YoutubePlayerFlags(
          autoPlay: true,
        ),
      );
    else {
      ctx.state.youtubePlayerController.load(ctx.state.streamAddress);
    }
  } else
    ctx.state.chewieController = ChewieController(
        customControls: CustomCupertinoControls(
          backgroundColor: Colors.black,
          iconColor: Colors.white,
        ),
        autoInitialize: true,
        autoPlay: true,
        videoPlayerController: ctx.state.videoControllers[index]);
}
