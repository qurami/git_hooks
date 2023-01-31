import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// return bool function
typedef UserBackFun = Future<bool> Function();
String _rootDir = Directory.current.path;

/// utils class
class Utils {
  /// check the file Path
  static String uri(String filePath) {
    return path.fromUri(path.toUri(filePath));
  }

  /// get path of git_hooks library
  static String? getOwnPath() {
    final pacPath = path.fromUri('${path.current}/.packages');
    final pac = File(pacPath);
    final a = pac.readAsStringSync();
    final b = a.split('\n');
    late String resPath;
    for (final v in b) {
      if (v.startsWith('git_hooks:')) {
        final index = v.indexOf(':');
        final lastIndex = v.lastIndexOf('lib');
        resPath = v.substring(index + 1, lastIndex);
      }
    }
    resPath = path.fromUri(resPath);
    if (path.isRelative(resPath)) {
      resPath = path.canonicalize(resPath);
    }
    if (!Directory(resPath).existsSync()) {
      return null;
    }
    return resPath;
  }

  /// Returns the current branch name
  static String getBranchName() {
    //ref: refs/heads/chore-pre-commit
    final headFile = File(Utils.uri('${Directory.current.path}/.git/HEAD'));
    final headString = headFile.readAsStringSync();
    return headString.replaceFirst('ref: refs/heads/', '').trim();
  }

  /// get commit edit msg from '.git/COMMIT_EDITMSG'
  static String getCommitEditMsg() {
    final rootDir = Directory.current;
    final myFile = File(Utils.uri('${rootDir.path}/.git/COMMIT_EDITMSG'));
    final commitMsg = myFile.readAsStringSync();
    return commitMsg;
  }

  static String _gitHookFolder = '$_rootDir/.git/hooks/';

  /// get git hooks folder
  static String get gitHookFolder => uri(_gitHookFolder);

  /// test create git hooks file
  @visibleForTesting
  static void setGitHooksFolder(String path) {
    _gitHookFolder = '$path/';
  }

  /// Returns the list of modified file names
  static Future<List<String>> getModifiedFileNames({
    List<String> directories = const ['lib', 'test'],
  }) async {
    final result = await Process.run(
      'git',
      ['diff', '--cached', '--name-only', '--diff-filter=ACM'],
    );

    final fileNames = (result.stdout as String)
        // remove the last empty line
        .trimRight()
        // split file names by line
        .split('\n')
        // consider only folders starting with `directories`
        .where(
          (fileName) => fileName.startsWith(RegExp(directories.join('|'))),
        );
    return fileNames.toList();
  }

  /// Check if the branch name is supported for the beginning of the name
  static void isBranchNameValid(
    String branchName, {
    // additional branch names that you want to support, optional
    List<String>? additionalBranchNames,
  }) {
    final supportedBranchNames = [
      'main',
      'master',
      'chore',
      'bugfix',
      'feat',
      'release',
      'hotfix',
      // Doesn't trigger CI
      'unmanaged',
      ...?additionalBranchNames,
    ];
    // Matches all the words that preceed a `-` or `/` character.
    final re = RegExp("r'^${supportedBranchNames.join('|')}[-/]");
    final isBranchValid = re.hasMatch(branchName);
    if (!isBranchValid) {
      throw Exception(
        'the branch name `$branchName` starts with an invalid value, supported values are: $supportedBranchNames',
      );
    }
  }
}
