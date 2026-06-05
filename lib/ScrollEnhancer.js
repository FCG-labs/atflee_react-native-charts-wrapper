import React, {Component} from 'react';
import { UIManager, findNodeHandle} from 'react-native';


function getCommand(extendedChart, commandName) {
  if (global?.nativeFabricUIManager) {
    return commandName;
  }

  return UIManager.getViewManagerConfig(extendedChart.getNativeComponentName()).Commands[commandName];
}

export default function ScrollEnhancer(Chart) {
  return class ScrollExtended extends Chart {
    setDataAndLockIndex(data) {
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.getNativeComponentRef()),
        getCommand(this, 'setDataAndLockIndex'),
        [data]
      );
    }
  }
}