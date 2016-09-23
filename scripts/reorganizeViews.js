fs = require('fs')
_ = require('lodash')
_.string = require('underscore.string')

var directories = ['./app/views', './app/templates', './app/styles', './test/app/views']
var groupings = {};

while(directories.length) {
  directory = directories.pop()
  console.log('*', directory)

  fs.readdirSync(directory).forEach((fileOrDir) => {
    absPath = directory + '/' + fileOrDir
    stat = fs.statSync(absPath)
  
    // .coffee => .js
    if(stat.isFile()) {
      var group = _.string.underscored(fileOrDir.split('.')[0])
      if(_.string.endsWith(group, '_view')) {
        if(!groupings[group]) groupings[group] = []
        groupings[group].push(absPath)
      }
    }
  
    // Add to list of directories to walk
    if(stat.isDirectory()) {
      directories.push(absPath);
    }
  })
}

_.forEach(groupings, (files) => {
  var view = _.remove(files, (file) => _.string.startsWith(file, './app/views/'))[0]
  if(!view || _.size(files) === 0)
    return;
  console.log('view', view, 'files', files)
  var template = _.remove(files, (file) => _.string.startsWith(file, './app/templates/'))[0]
  var viewFolder = view.slice(0, _.lastIndexOf(view, '/'))
  if(template) {
    viewFileData = fs.readFileSync(view, {encoding: 'utf8'})
    templateFileName = template.slice(_.lastIndexOf(template, '/'))
    newTemplatePath = viewFolder + templateFileName
    console.log('renaming', template, 'to', newTemplatePath)
    bareTemplateName = templateFileName.replace('.jade', '').slice(1)
    re = new RegExp('templates/(\\S+\\/)?'+bareTemplateName, 'gm')
    newViewFileData = viewFileData.replace(re, './'+bareTemplateName)
    fs.writeFileSync(view, newViewFileData, {encoding: 'utf8'})
    fs.renameSync(template, newTemplatePath)
    throw new Error('stop')
  }
});
