import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/models/meeting_model.dart';

List<Meeting> recentMeetings = [];

class BrowseTab extends StatelessWidget {
  const BrowseTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20.0,
      runSpacing: 20.0,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: 150.0,
            height: 150.0,
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: 150.0,
            height: 150.0,
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: 150.0,
            height: 150.0,
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: 150.0,
            height: 150.0,
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: 150.0,
            height: 150.0,
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
      ],
    );
  }
}