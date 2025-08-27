//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Directive, ElementRef, Input } from '@angular/core';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { combineLatest } from 'rxjs';
import { take } from 'rxjs/operators';
import {
  toDOMString,
  projectIconData,
  versionsIconData,
  briefcaseIconData,
  SVGData,
} from '@openproject/octicons-angular';

import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

interface Position {
  top:number;
  left:number;
}

interface Feedback {
  element:{ element:JQuery };
  target:{ width:number };
}

@Directive({
  selector: '[opWorkspaceCreateDropdown]',
  standalone: false,
})
export class OpWorkspaceCreateDropdownDirective extends OpContextMenuTrigger {
  @Input() dropdownActive:boolean;

  public isOpen = false;

  constructor(
    readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly I18n:I18nService,
    readonly currentUser:CurrentUserService,
    readonly pathHelper:PathHelperService,
    readonly sanitizer:DomSanitizer,
  ) {
    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.isOpen = !this.isOpen;
    if (this.isOpen) {
      this.buildItems(evt);
    } else {
      this.opContextMenu.close();
    }
  }

  onClose(focus = false) {
    this.isOpen = false;
    super.onClose(focus);
  }

  /**
   * Override positioning to make dropdown same width as button
   */
  public positionArgs(openerEvent:JQuery.TriggeredEvent) {
    const baseArgs = super.positionArgs(openerEvent);
    return {
      ...baseArgs,
      using:(position:Position, feedback:Feedback) => {
        const dropdown = feedback.element.element;
        dropdown.css({
          left: `${position.left.toString()}px`,
          top: `${position.top.toString()}px`,
          width: `${feedback.target.width.toString()}px`
        });
      }
    };
  }

  private buildItems(evt:JQuery.TriggeredEvent) {
    // Check permissions for each workspace type
    combineLatest([
      this.currentUser.hasCapabilities$('projects/create', 'global'),
      this.currentUser.hasCapabilities$('portfolios/create', 'global'),
      this.currentUser.hasCapabilities$('programs/create', 'global'),
    ])
      .pipe(take(1))
      .subscribe(([canCreateProject, canCreatePortfolio, canCreateProgram]) => {
        const items = [];

        if (canCreateProject) {
          items.push({
            linkText: this.I18n.t('js.label_project'),
            href: this.pathHelper.projectsNewPath(),
            octicon: this.generateOcticon(projectIconData)
          });
        }

        if (canCreatePortfolio) {
          items.push({
            linkText: this.I18n.t('js.label_portfolio'),
            href: this.pathHelper.portfoliosNewPath(),
            octicon: this.generateOcticon(briefcaseIconData)
          });
        }

        if (canCreateProgram) {
          items.push({
            linkText: this.I18n.t('js.label_program'),
            href: this.pathHelper.programsNewPath(),
            octicon: this.generateOcticon(versionsIconData)
          });
        }

        this.items = items;
        this.opContextMenu.show(this, evt);
      });
  }

  private generateOcticon(iconData:SVGData):SafeHtml {
    const htmlString = toDOMString(iconData, 'small', { 'aria-hidden': 'true', class: 'octicon' });
    return this.sanitizer.bypassSecurityTrustHtml(htmlString);
  }
}
